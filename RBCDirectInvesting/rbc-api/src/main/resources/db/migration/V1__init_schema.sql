CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(200) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE accounts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_number  VARCHAR(20) NOT NULL UNIQUE,
    account_type    VARCHAR(20) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'CAD',
    cash_balance    DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE holdings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id      UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    symbol          VARCHAR(20) NOT NULL,
    exchange        VARCHAR(10) NOT NULL DEFAULT 'TSX',
    quantity        DECIMAL(15,4) NOT NULL,
    avg_cost        DECIMAL(15,4) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'CAD',
    UNIQUE (account_id, symbol, exchange)
);

CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id      UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    symbol          VARCHAR(20) NOT NULL,
    exchange        VARCHAR(10) NOT NULL DEFAULT 'TSX',
    side            VARCHAR(10) NOT NULL,
    order_type      VARCHAR(15) NOT NULL,
    quantity        DECIMAL(15,4) NOT NULL,
    limit_price     DECIMAL(15,4),
    stop_price      DECIMAL(15,4),
    duration        VARCHAR(10) NOT NULL DEFAULT 'DAY',
    gtd_date        DATE,
    status          VARCHAR(15) NOT NULL DEFAULT 'PENDING',
    filled_quantity DECIMAL(15,4) DEFAULT 0,
    filled_avg_price DECIMAL(15,4),
    estimated_cost  DECIMAL(15,2),
    commission      DECIMAL(10,2) DEFAULT 9.95,
    submitted_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    filled_at       TIMESTAMP,
    cancelled_at    TIMESTAMP
);

CREATE TABLE transactions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id      UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    order_id        UUID REFERENCES orders(id),
    type            VARCHAR(20) NOT NULL,
    symbol          VARCHAR(20),
    quantity        DECIMAL(15,4),
    price           DECIMAL(15,4),
    amount          DECIMAL(15,2) NOT NULL,
    commission      DECIMAL(10,2) DEFAULT 0,
    description     TEXT,
    settled_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE watchlists (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE watchlist_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    watchlist_id    UUID NOT NULL REFERENCES watchlists(id) ON DELETE CASCADE,
    symbol          VARCHAR(20) NOT NULL,
    exchange        VARCHAR(10) NOT NULL DEFAULT 'TSX',
    added_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (watchlist_id, symbol, exchange)
);

CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_holdings_account ON holdings(account_id);
CREATE INDEX idx_orders_account ON orders(account_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_settled ON transactions(settled_at);
CREATE INDEX idx_watchlist_items_wl ON watchlist_items(watchlist_id);
