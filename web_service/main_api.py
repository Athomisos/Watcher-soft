#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   REST API of Watcher-Soft                                ****#
#*******************************************************************************************#

__name__ = "Watcher-Soft-API"

import flask, sqlite3, sys, json, include, os
from flask import render_template, jsonify
from flask_assets import Bundle, Environment
from flask_cors import CORS
from flask_mail import Mail, Message

app = flask.Flask(__name__)
CORS(app)
app.config["DEBUG"] = True

with open(sys.path[0]+"/../alerters/conf/mail.conf.json", "r") as conf_file:
    data = json.load(conf_file)

app.config['MAIL_SERVER']=data['MAIL_SERVER']
app.config['MAIL_PORT'] = data['MAIL_PORT']
app.config['MAIL_USERNAME'] = data['MAIL_USERNAME']
app.config['MAIL_PASSWORD'] = data['MAIL_PASSWORD']
app.config['MAIL_USE_TLS'] = data['MAIL_USE_TLS']
app.config['MAIL_USE_SSL'] = data['MAIL_USE_SSL']

mail = Mail(app)

###########################################| INDEX |###########################################
@app.route('/', methods=['GET'])
def home():
    return render_template("index.html")

###########################################| SEND MAIL |###########################################
@app.route("/mail", methods=['POST'])
def sendMail():
  if(flask.request.remote_addr == "127.0.0.1"):
    postJSON = flask.request.get_json()
    if(("body" in postJSON) and ("title" in postJSON)):
      print(type(postJSON))
      if("bcc" in postJSON):
        msg = Message(postJSON["title"], sender = app.config['MAIL_USERNAME'], recipients = [postJSON["MAIL_REPORT"]], bcc=postJSON["bcc"])
      else:
        msg = Message(postJSON["title"], sender = app.config['MAIL_USERNAME'], recipients = [postJSON["MAIL_REPORT"]])
      msg.body = postJSON["body"]
      mail.send(msg)
      return postJSON
  else:
    return render_template("400.html"), 400


###########################################| GET RRD PNG |###########################################
@app.route("/img/rrd", methods=['GET'])
def getIMG():
  file = flask.request.args.get('name')
  if( os.path.dirname(file) == ''):
    path_img = sys.path[0]+"/../datas/png/" + file
    return send_file(path_img, mimetype='image/png')
  else:
    return render_template("400.html"), 400

###########################################| GET ALL .DAT |###########################################
@app.route("/rrd/", methods=['GET'])
def getAllRRA():
  jsonOUTPUT = []
  path = sys.path[0] + "/../datas/dat/"
  for root, dirs, files in os.walk(str(path)):
    for file in files:
      if(file[0] != "."):
        jsonOUTPUT.append(file)
  return jsonify(jsonOUTPUT)

###########################################| GET .DAT |###########################################
@app.route("/rrd/json", methods=['GET'])
def parseDATA():
  file = flask.request.args.get("filename")
  jsonOUT = []
  if( os.path.dirname(file) == ''):
    dat_file = open(sys.path[0] + "/../datas/dat/" + file, 'r').read().splitlines()
    for i in range(len(dat_file)):
      if(dat_file[i] != "" and dat_file[i].find("_") == -1):
        temp = dat_file[i].split(":")
        temp[0] = int(temp[0])
        temp[1] = temp[1].replace(" ", "").split("e")
        temp[1] = float(temp[1][0])*pow(10, int(temp[1][1]))
        jsonOUT.append(temp)
    return jsonify(jsonOUT)
  else:
    return render_template("400.html"), 400

###########################################| GET PROBES INFO |###########################################
@app.route("/probes", methods=['GET'])
def probedb():
  out = []
  with  sqlite3.connect(sys.path[0]+'/../datas/sql/watcher.db') as db:
    for row in db.execute("SELECT * FROM probers"):
      out.append(row)
  return jsonify(out)


###########################################| CUSTOM PAGE FOR HTTP ERROR |###########################################
@app.errorhandler(404)
def not_found(error):
    return render_template("404.html"), 404

@app.errorhandler(400)
def not_found(error):
    return render_template("400.html"), 400

@app.errorhandler(405)
def not_found(error):
    return render_template("405.html"), 405

app.run(host="0.0.0.0", port=5000)