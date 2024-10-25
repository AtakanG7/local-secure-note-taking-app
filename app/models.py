from app import db
from datetime import datetime
from cryptography.fernet import Fernet
import os

# Key management - moved to /etc/simple-notes
KEY_FILE = '/etc/simple-notes/.key'

def get_or_create_key():
    if not os.path.exists(KEY_FILE):
        key = Fernet.generate_key()
        with open(KEY_FILE, 'wb') as key_file:
            key_file.write(key)
        os.chmod(KEY_FILE, 0o600)
    else:
        with open(KEY_FILE, 'rb') as key_file:
            key = key_file.read()
    return key

cipher_suite = Fernet(get_or_create_key())

class Note(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.LargeBinary, nullable=False)
    content = db.Column(db.LargeBinary, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    @property
    def decrypted_title(self):
        return cipher_suite.decrypt(self.title).decode()

    @property
    def decrypted_content(self):
        return cipher_suite.decrypt(self.content).decode()

    def encrypt_data(self, title, content):
        self.title = cipher_suite.encrypt(title.encode())
        self.content = cipher_suite.encrypt(content.encode())

class Counter(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
