import atexit
import io
import json
import os
from argparse import ArgumentParser
from pathlib import Path

from flask import Flask, render_template, request, send_file

from markupsafe import escape

from validate_form import validate_form
from utils import DB_NAME
from SimpleDB import MiniDB
from config_gen import gen_config, download_cert_archive

import urllib.parse as urlparse

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/submit", methods=['POST'])
def form_submit():
    content_type = request.headers.get('Content-Type')
    if content_type != 'application/json':
        return f"{content_type} not supported"

    # safe deepcopy
    form_data = json.loads(json.dumps(request.json))
    try:
        validate_form(form_data)
    except ValueError as e:
        return render_template("index.html", form_error=str(e))

    # generate config and certificate
    bird_config = gen_config(form_data, app)
    bird_config = str(escape(bird_config)).replace('\n', '<br/>')

    return render_template("config.html",
                           bird_config_hint=bird_config,
                           peer_id=urlparse.quote(form_data['local_ip']))


@app.route("/fetch-cert/<peer_id>")
def fetch_cert(peer_id: str):
    peer_id = urlparse.unquote(peer_id)

    try:
        with download_cert_archive(peer_id) as spooled_archive:
            bio = io.BytesIO(spooled_archive.read())
        return send_file(bio,
                         mimetype='application/x-zip-compressed',
                         as_attachment=True,
                         download_name='certificates.zip')
    except ValueError as e:
        return f"{str(e)}"


@app.route("/contact")
def contact():
    return "Salut à tous"


def close_db():
    MiniDB(DB_NAME).db.close()
    print('DB is closed')


def remove_db():
    # remove generated certificates
    db = MiniDB(DB_NAME).db

    for client in db['clients']:
        print(client)
        client['priv_key_path'].unlink()
        client['cert_path'].unlink()

    # then remove DB
    Path(DB_NAME).unlink(missing_ok=True)


# Here's how you create a route
# @app.route("/routeName")
# def functionName():
#    return render_template("fileName.html")

if __name__ == "__main__":
    parser = ArgumentParser(description='Cert Web generator')
    parser.add_argument('-d', '--delete-db',
                        action='store_true', dest='delete_db',
                        help='Delete Peering DB on start (debug purposes). '
                             'Should not be set on production unless you know '
                             'what you are doing...')
    _args = parser.parse_args()

    if _args.delete_db:
        remove_db()

    atexit.register(close_db)
    app.run(debug=True, host='127.0.0.1', port=5000)
