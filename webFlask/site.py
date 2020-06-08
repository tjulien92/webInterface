# helloTest.py
# at the end point / call method hello which returns "hello world"
from flask import Flask, render_template,request

app = Flask(__name__)

@app.route("/")
def home():
    return render_template("home.html")
    



@app.route("/financial",methods=['GET', 'POST'])
def about():
    if request.method == 'POST':
        print(request.form)
        return render_template('financial.html')

    return render_template("financial.html")

if __name__ == '__main__':
    app.run(host='0.0.0.0')