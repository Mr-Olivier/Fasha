-- Powers chat read receipts (✓✓) - whether the RECIPIENT of a message has
-- opened the conversation since it arrived. Defaults false so every
-- existing message starts "unread", which is harmless: the next time
-- either party opens that conversation, MessageService.list() catches up
-- and marks anything sent by the other party as read.
ALTER TABLE messages ADD COLUMN read BOOLEAN NOT NULL DEFAULT FALSE;
