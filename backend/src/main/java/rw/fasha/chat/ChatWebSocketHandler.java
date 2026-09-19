package rw.fasha.chat;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper; // Jackson 3 (Spring Boot 4) - not com.fasterxml.jackson
import rw.fasha.booking.Booking;
import rw.fasha.booking.BookingRepository;
import rw.fasha.provider.ProviderProfileRepository;
import rw.fasha.security.JwtService;
import rw.fasha.security.RevokedTokenRepository;

import java.io.IOException;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Pushes new chat messages to connected clients in real time, replacing
 * the mobile app's previous 4-second poll (ChatScreen's Timer.periodic).
 * REST (MessageController) is still how a message actually gets SENT and
 * how a client loads history on screen-open - this handler ONLY delivers
 * live updates to whoever's already connected and subscribed to a
 * booking's chat.
 *
 * Deliberately a raw WebSocketHandler, not Spring's STOMP/message-broker
 * layer - this app has exactly one kind of subscription ("this booking's
 * messages"), so STOMP's extra topic/broker machinery would be more
 * moving parts for no real benefit at this scale.
 *
 * Auth here is NOT the standard "Authorization: Bearer" header every REST
 * endpoint uses - browsers' native WebSocket API can't send custom
 * headers on the handshake at all, so the access token travels as a
 * query parameter instead (?bookingId=...&token=...). See
 * ChatWebSocketConfig/SecurityConfig for why the HTTP handshake itself is
 * permitAll; THIS class is where real authentication (is the token valid
 * and not revoked) and authorization (is this user actually one of this
 * booking's two parties) both happen, immediately on connect - same
 * "don't reveal what you can't touch" reasoning as
 * MessageService.findAccessibleBooking, just re-derived here since a
 * WebSocket connection has no access to that HTTP-request-scoped code
 * path.
 */
@Component
@RequiredArgsConstructor
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatWebSocketHandler.class);

    private final JwtService jwtService;
    private final RevokedTokenRepository revokedTokenRepository;
    private final BookingRepository bookingRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final ObjectMapper objectMapper;

    private final Map<UUID, Set<WebSocketSession>> sessionsByBookingId = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws IOException {
        UUID bookingId = parseUuid(queryParam(session, "bookingId"));
        UUID userId = authenticate(session);

        if (bookingId == null || userId == null || !isParticipant(userId, bookingId)) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }

        // Stashed here (rather than re-derived per message) so
        // handleTextMessage below - which only ever gets the "typing"
        // sentinel, never bookingId/userId again - knows who's typing and
        // where to relay it without another auth/participant lookup.
        session.getAttributes().put(ATTR_BOOKING_ID, bookingId);
        session.getAttributes().put(ATTR_USER_ID, userId);
        sessionsByBookingId.computeIfAbsent(bookingId, id -> ConcurrentHashMap.newKeySet()).add(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessionsByBookingId.values().forEach(sessions -> sessions.remove(session));
    }

    private static final String ATTR_BOOKING_ID = "bookingId";
    private static final String ATTR_USER_ID = "userId";

    /**
     * The only frame a client ever sends over this socket - the literal
     * text "typing", fired (debounced) while they have text entered on
     * ChatScreen. Deliberately not JSON: there's exactly one thing a client
     * says here, so a whole envelope/parser for it would be more machinery
     * than the message warrants. Relayed to every OTHER session on this
     * same booking as a small JSON event (distinguishable from a
     * MessageResponse by its "type" key, which MessageResponse never has) -
     * never persisted, since "is still typing" has no meaning once the
     * moment passes.
     */
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        if (!"typing".equals(message.getPayload())) return;

        UUID bookingId = (UUID) session.getAttributes().get(ATTR_BOOKING_ID);
        UUID userId = (UUID) session.getAttributes().get(ATTR_USER_ID);
        if (bookingId == null || userId == null) return;

        Set<WebSocketSession> sessions = sessionsByBookingId.get(bookingId);
        if (sessions == null) return;

        String payload = "{\"type\":\"typing\",\"senderId\":\"" + userId + "\"}";
        for (WebSocketSession other : sessions) {
            if (other == session || !other.isOpen()) continue;
            try {
                other.sendMessage(new TextMessage(payload));
            } catch (IOException e) {
                log.warn("Failed to relay a typing indicator to one session for booking {}", bookingId, e);
            }
        }
    }

    /** Called by MessageService.clearChat right after every message/attachment for this booking is deleted - tells whoever's got this chat open right now to empty their view immediately, same distinguishing-by-"type"-key convention as the "typing" event. A no-op if nobody's connected; the other party just sees an empty conversation next time they open it. */
    public void broadcastCleared(UUID bookingId) {
        Set<WebSocketSession> sessions = sessionsByBookingId.get(bookingId);
        if (sessions == null || sessions.isEmpty()) return;

        String payload = "{\"type\":\"cleared\"}";
        for (WebSocketSession session : sessions) {
            try {
                if (session.isOpen()) {
                    session.sendMessage(new TextMessage(payload));
                }
            } catch (IOException e) {
                log.warn("Failed to deliver a chat-cleared event to one session for booking {}", bookingId, e);
            }
        }
    }

    /** Called by MessageService right after a message is persisted - delivers it to every client currently connected for this booking. A no-op (not an error) if nobody's connected, e.g. the other party has the app closed - they'll see it via the normal GET on next open. */
    public void broadcast(UUID bookingId, MessageResponse message) {
        Set<WebSocketSession> sessions = sessionsByBookingId.get(bookingId);
        if (sessions == null || sessions.isEmpty()) return;

        String payload;
        try {
            payload = objectMapper.writeValueAsString(message);
        } catch (JacksonException e) {
            log.error("Failed to serialize a live chat message for booking {}", bookingId, e);
            return;
        }

        for (WebSocketSession session : sessions) {
            try {
                if (session.isOpen()) {
                    session.sendMessage(new TextMessage(payload));
                }
            } catch (IOException e) {
                log.warn("Failed to deliver a live chat message to one session for booking {}", bookingId, e);
            }
        }
    }

    /** Null (not an exception) for anything wrong with the token - an unauthenticated connection is just refused, same as a REST request with no/invalid Authorization header. */
    private UUID authenticate(WebSocketSession session) {
        String token = queryParam(session, "token");
        if (token == null) return null;
        try {
            UUID jti = jwtService.extractJti(token);
            if (revokedTokenRepository.existsById(jti)) return null;
            return jwtService.extractUserId(token);
        } catch (Exception e) {
            return null;
        }
    }

    private boolean isParticipant(UUID userId, UUID bookingId) {
        return bookingRepository.findById(bookingId)
                .map(booking -> booking.getCustomerId().equals(userId) || isThisBookingsProvider(userId, booking))
                .orElse(false);
    }

    private boolean isThisBookingsProvider(UUID userId, Booking booking) {
        return providerProfileRepository.findByUserId(userId)
                .map(profile -> profile.getId().equals(booking.getProviderProfileId()))
                .orElse(false);
    }

    private String queryParam(WebSocketSession session, String name) {
        URI uri = session.getUri();
        if (uri == null || uri.getQuery() == null) return null;
        return Arrays.stream(uri.getQuery().split("&"))
                .map(pair -> pair.split("=", 2))
                .filter(pair -> pair.length == 2 && pair[0].equals(name))
                .map(pair -> URLDecoder.decode(pair[1], StandardCharsets.UTF_8))
                .findFirst()
                .orElse(null);
    }

    private UUID parseUuid(String raw) {
        if (raw == null) return null;
        try {
            return UUID.fromString(raw);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
