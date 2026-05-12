const express = require('express');
const cors = require('cors');
const multer = require('multer');
const mysql = require('mysql2');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;
const HOST = '0.0.0.0';

const dbConfig = {
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'admin123',
  database: 'flutterdb'
};

const uploadDirectory = path.join(__dirname, 'uploads');

if (!fs.existsSync(uploadDirectory)) {
  fs.mkdirSync(uploadDirectory, { recursive: true });
}

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/images', express.static('uploads'));

const db = mysql.createConnection(dbConfig);

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDirectory);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

function readMessage(body, fallback) {
  try {
    const parsed = JSON.parse(body);
    if (parsed && parsed.message) {
      return parsed.message;
    }
  } catch (error) {
    // Ignore parse errors and fall back to the default message.
  }

  return fallback;
}

function ensureProductsSchema(callback) {
  ensureTableColumn('products', 'stock', 'INT NOT NULL DEFAULT 0', (error) => {
    if (error) {
      return callback(error);
    }

    ensureTableColumn(
      'products',
      'description',
      "VARCHAR(500) NOT NULL DEFAULT ''",
      callback
    );
  });
}

function ensureTableColumn(tableName, columnName, definition, callback) {
  const query =
    'SELECT COUNT(*) AS count FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?';

  db.query(query, [dbConfig.database, tableName, columnName], (error, rows) => {
    if (error) {
      return callback(error);
    }

    if (rows[0].count > 0) {
      return callback(null);
    }

    db.query(
      `ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${definition}`,
      callback
    );
  });
}

function ensureUsersSchema(callback) {
  const sql = `
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      email VARCHAR(255) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL
    )
  `;

  db.query(sql, callback);
}

db.connect((error) => {
  if (error) {
    throw error;
  }

  console.log('Connected to MySQL');

  ensureUsersSchema((usersSchemaError) => {
    if (usersSchemaError) {
      throw usersSchemaError;
    }

    ensureProductsSchema((schemaError) => {
      if (schemaError) {
        throw schemaError;
      }

      app.listen(PORT, HOST, () => {
        console.log(`Server running on http://${HOST}:${PORT}`);
      });
    });
  });
});

app.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  const normalizedEmail = email.trim().toLowerCase();
  const sql = 'SELECT id FROM users WHERE email = ? AND password = ? LIMIT 1';

  db.query(sql, [normalizedEmail, password], (error, rows) => {
    if (error) {
      return res.status(500).json({ message: 'Error logging in.' });
    }

    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    return res.json({ message: 'Login successful' });
  });
});

app.post('/register', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  const normalizedEmail = email.trim().toLowerCase();
  if (!normalizedEmail) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  if (password.length < 6) {
    return res.status(400).json({
      message: 'Password must be at least 6 characters long.',
    });
  }

  db.query(
    'SELECT id FROM users WHERE email = ? LIMIT 1',
    [normalizedEmail],
    (error, rows) => {
      if (error) {
        return res.status(500).json({ message: 'Error creating account.' });
      }

      if (rows.length > 0) {
        return res.status(409).json({
          message: 'An account with that email already exists.',
        });
      }

      db.query(
        'INSERT INTO users (email, password) VALUES (?, ?)',
        [normalizedEmail, password],
        (insertError) => {
          if (insertError) {
            return res.status(500).json({ message: 'Error creating account.' });
          }

          return res.status(201).json({ message: 'Account created successfully.' });
        }
      );
    }
  );
});

app.get('/products', (req, res) => {
  const sql =
    'SELECT id, name, price, stock, description, image_url FROM products ORDER BY id DESC';

  db.query(sql, (error, rows) => {
    if (error) {
      return res.status(500).json({ message: 'Error fetching products' });
    }

    return res.json(rows);
  });
});

app.post('/products', upload.single('image'), (req, res) => {
  const { name, price, stock, description = '' } = req.body;
  const imageUrl = req.file ? req.file.filename : '';
  const parsedPrice = Number.parseFloat(price);
  const parsedStock = Number.parseInt(stock, 10);
  const parsedDescription = String(description).trim().slice(0, 500);

  if (!name || Number.isNaN(parsedPrice) || Number.isNaN(parsedStock)) {
    return res.status(400).json({ message: 'Invalid product data.' });
  }

  const sql =
    'INSERT INTO products (name, price, stock, description, image_url) VALUES (?, ?, ?, ?, ?)';

  db.query(
    sql,
    [name.trim(), parsedPrice, parsedStock, parsedDescription, imageUrl],
    (error, result) => {
      if (error) {
        return res.status(500).json({ message: 'Error adding product' });
      }

      return res.json({
        message: 'Product added',
        id: result.insertId,
        image_url: imageUrl
      });
    }
  );
});

app.put('/products/:id', upload.single('image'), (req, res) => {
  const {
    name,
    price,
    stock,
    description = '',
    existing_image: existingImage,
  } = req.body;
  const id = req.params.id;
  const parsedPrice = Number.parseFloat(price);
  const parsedStock = Number.parseInt(stock, 10);
  const parsedDescription = String(description).trim().slice(0, 500);
  const imageUrl = req.file ? req.file.filename : existingImage || '';

  if (!name || Number.isNaN(parsedPrice) || Number.isNaN(parsedStock)) {
    return res.status(400).json({ message: 'Invalid product data.' });
  }

  const sql =
    'UPDATE products SET name = ?, price = ?, stock = ?, description = ?, image_url = ? WHERE id = ?';

  db.query(
    sql,
    [name.trim(), parsedPrice, parsedStock, parsedDescription, imageUrl, id],
    (error) => {
      if (error) {
        return res.status(500).json({ message: 'Error updating product' });
      }

      return res.json({
        message: 'Product updated',
        image_url: imageUrl
      });
    }
  );
});

app.delete('/products/:id', (req, res) => {
  const id = req.params.id;

  db.query('DELETE FROM products WHERE id = ?', [id], (error) => {
    if (error) {
      return res.status(500).json({ message: 'Error deleting product' });
    }

    return res.json({ message: 'Product deleted' });
  });
});
