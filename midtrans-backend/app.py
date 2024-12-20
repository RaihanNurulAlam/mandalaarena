from flask import Flask, jsonify, request # type: ignore
import requests # type: ignore

app = Flask(__name__)

# Ganti dengan server key Anda
MIDTRANS_SERVER_KEY = "Your-Midtrans-Server-Key"
MIDTRANS_API_URL = "https://app.sandbox.midtrans.com/snap/v1/transactions"

@app.route("/create_snap_token", methods=["POST"])
def create_snap_token():
    data = request.json
    headers = {
        "Authorization": f"Basic {MIDTRANS_SERVER_KEY}",
        "Content-Type": "application/json",
    }
    response = requests.post(MIDTRANS_API_URL, json=data, headers=headers)
    return jsonify(response.json())

if __name__ == "__main__":
    app.run(port=5000)
