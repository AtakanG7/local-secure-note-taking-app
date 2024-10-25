from flask import render_template, request, redirect, url_for
from app import app, db
from app.models import Note, Counter
from datetime import datetime

@app.route('/')
def index():
    notes = Note.query.order_by(Note.created_at.desc()).all()
    counters = Counter.query.order_by(Counter.created_at.asc()).all()
    return render_template('index.html', notes=notes, counters=counters)

@app.route('/note/new', methods=['GET', 'POST'])
def new_note():
    if request.method == 'POST':
        note = Note()
        note.encrypt_data(
            request.form['title'],
            request.form['content']
        )
        db.session.add(note)
        db.session.commit()
        return redirect(url_for('index'))
    return render_template('edit_note.html')

@app.route('/note/<int:id>/make_current')
def make_current(id):
    note = Note.query.get_or_404(id)
    note.created_at = datetime.utcnow()
    db.session.commit()
    return redirect(url_for('index'))

@app.route('/note/<int:id>/edit', methods=['GET', 'POST'])
def edit_note(id):
    note = Note.query.get_or_404(id)
    if request.method == 'POST':
        note.encrypt_data(
            request.form['title'],
            request.form['content']
        )
        db.session.commit()
        return redirect(url_for('index'))
    return render_template('edit_note.html', note={
        'id': note.id,
        'title': note.decrypted_title,
        'content': note.decrypted_content
    })

@app.route('/note/<int:id>/delete')
def delete_note(id):
    note = Note.query.get_or_404(id)
    db.session.delete(note)
    db.session.commit()
    return redirect(url_for('index'))

@app.route('/counter/add', methods=['GET', 'POST'])
def add_counter():
    if request.method == 'POST':
        number = request.form.get('number', type=int)
        if number:
            counter = Counter(number=number)
            db.session.add(counter)
            db.session.commit()
        return redirect(url_for('index'))
    return render_template('add_counter.html')

@app.route('/counter/<int:id>/delete')
def delete_counter(id):
    counter = Counter.query.get_or_404(id)
    db.session.delete(counter)
    db.session.commit()
    return redirect(url_for('index'))
