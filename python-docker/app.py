from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, Intuit!   '

@app.route('/what-is-my-name')
def name():
    return 'Justin     '

@app.route('/sq/<num>')
def sqRt(num):
    return str(int(num) * int(num))