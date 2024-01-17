CREATE TABLE mock_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

INSERT INTO mock_table (name, description) VALUES
('Test Item 1', 'Description for test item 1'),
('Test Item 2', 'Description for test item 2'),
('Test Item 3', 'Description for test item 3');