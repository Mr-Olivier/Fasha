-- The "What stood out?" chips on the Leave a Review screen (On time / Fair
-- price / Clean work / Polite) - a customer can pick any number of them
-- alongside their star rating and free-text comment.
--
-- A join table, not a comma-separated column on reviews, so a provider's
-- tag counts stay queryable later (e.g. "12 reviews mention On time" as a
-- profile badge) without parsing a string column.
-- Composite primary key (review_id, tag), no surrogate id - mapped from the
-- Java side as a plain @ElementCollection<ReviewTag> on Review, which is
-- exactly this shape (owning-row fk + one value, tag can't repeat for the
-- same review).
CREATE TABLE review_tags (
    review_id  UUID NOT NULL REFERENCES reviews (id),
    tag        VARCHAR(20) NOT NULL,

    CONSTRAINT chk_review_tags_tag CHECK (tag IN ('ON_TIME', 'FAIR_PRICE', 'CLEAN_WORK', 'POLITE')),
    PRIMARY KEY (review_id, tag)
);

CREATE INDEX idx_review_tags_review_id ON review_tags (review_id);
