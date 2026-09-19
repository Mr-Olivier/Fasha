package rw.fasha.chat;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * Registers ChatWebSocketHandler at /ws/chat. setAllowedOriginPatterns("*")
 * mirrors this app's existing CORS stance (see SecurityConfig) - the API is
 * meant to be called from any origin during development/demo; real
 * authorization still happens per-connection inside the handler itself via
 * the token query parameter, not via origin checking.
 */
@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class ChatWebSocketConfig implements WebSocketConfigurer {

    private final ChatWebSocketHandler chatWebSocketHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(chatWebSocketHandler, "/ws/chat")
                .setAllowedOriginPatterns("*");
    }
}
