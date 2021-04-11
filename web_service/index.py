#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#*******************************************************************************************#
#*----- Auteur :        Aubertin Emmanuel               |  For: Watcher-Soft            ****#
#*----- GitHub :        https://github.com/Athomisos    | Twitter : @BlenderAubertin    ****#
#*----- Description :   Web app of Watcher-Soft                                        ****#
#*******************************************************************************************#

__name__ = "Watcher-Soft"

import flask, include, sqlite3, sys, urllib, os, requests, json
from flask import render_template, jsonify, send_file
from flask_assets import Bundle, Environment

app = flask.Flask(__name__)
app.config["DEBUG"] = True
assets = Environment(app)

###########################################| INDEX |###########################################
@app.route('/index', methods=['GET'])
@app.route('/', methods=['GET'])
def home():
  return render_template("index.html")

###########################################| DASHBOARD |###########################################
@app.route('/dashboard', methods=['GET'])
def dashboard():
    page = include.headdash +  include.header + "<style>  .graph:hover\
   {\
     z-index:555555 !important;\
   }</style>\n<script>\n\
    window.onload = function(){\n\
        setTimeout(() => { document.location.reload(); } , 60000);\n\
        \n\
          }\
      </script>\n   <div class=\"container mx-auto pt-4 text-blue-500\">\n\
            <h1 class=\"text-center font-bold uppercase text-xl sm:text-2xl md:text-2xl xl:text-4xl\">dashboard :</h1>\n\
            <div class=\"container lg:mx-8 xl:mx-8 2xl:mx-8 pt-4 text-blue-500 flex justify-center\">\n\
            <table class=\"table-fixed w-auto lg:w-1/2 xl:w-1/2 2xl:w-1/2 \">\n\
              <thead>\n\
                <tr>\n\
                  <th class=\"w-1/6\">Probes</th>\n\
                  <th class=\"w-1/4\">Status</th>\n\
                  <th class=\"w-auto\">Info</th>\n\
                </tr>\n\
              </thead>\n\
              <tbody>\n"
    print("\n\n\n\n"+sys.path[0]+'/../datas/sql/watcher.db'+"\n\n\n\n")
    probe_name = []
    rdd_prev = "<div class=\"mt-4 grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-2 gap-4\">\n"
    path_to_rrd = sys.path[0]+ "/../tests"
    print("\n\n\n\n Probes:"+flask.request.host_url[:-1]+":5000/probes \n\n\n\n")
    r = requests.get(flask.request.host_url[:-1]+":5000/probes")
    if(r.status_code == 200):
      for row in json.loads(r.text):
        NAME = row[1].split('_')[0]
        print("\n--\n--\n--\n"+str(row)+"\n--\n--\n--\n")
        page += "<tr>\n\
                      <td class=\"border border-blue-600\"><p class=\"flex justify-center\">" + NAME + "</p></td>\n"
        print("\n--\n--\n--\n"+str(row[4])+"\n--\n--\n--\n")
        if(int(row[4]) == 0):
          page +="<td class=\"border border-blue-600 bg-green-300\"><p class=\"flex justify-center\">Ok</p></td>\
                  <td class=\"border border-blue-600 \"><p class=\"flex justify-center\">" + row[5].split(':')[1].replace(",", "</p><p class=\"flex justify-center\">") + "</p></td>\n\
                </tr>\n"
        elif (int(row[4]) == "1"):
          page +="<td class=\"border border-blue-600 bg-yellow-400\"><p class=\"flex justify-center\">WARNING</p></td>\n\
                  <td class=\"border border-blue-600\"><p class=\"flex justify-center\">" + row[5].split(':')[1].replace(",", "</p><p class=\"flex justify-center\">") + "</p></td>\n\
                </tr>\n"
        else:
          page +="<td class=\"border border-blue-600 bg-red-500 text-gray-200\"><p class=\"flex justify-center\">CRITICAL</p></td>\n\
                  <td class=\"border border-blue-600 \"><p class=\"flex justify-center\">" + row[5].split(':')[1].replace(",", "</p><p class=\"flex justify-center\">") + "</p></td>\n\
                </tr>\n"    
        for x in row[6].split(" "):
          name_chart = x.split("=")[0].replace(" ", "") 
          if(name_chart != ""):
            rdd_prev +=  "<div id=\"" + name_chart + "\" class=\"z-0 graph transition duration-300 ease-in-out transform rounded-lg hover:-translate-y-1 hover:scale-125 hover:bg-blue-200\"></div>\n<script>Highcharts.getJSON(\n\
              '"+ flask.request.host_url[:-1] + ":5000/rrd/json?filename=data-" + name_chart+ ".dat',\n\
        function (data) {\n\
        Highcharts.chart('"+ name_chart +"', {\n\
          chart: {\n\
            backgroundColor: 'rgba(255, 255, 255, 0)',\
            zoomType: 'x',\n\
            borderColor: '#3B82F6',\n\
            borderRadius: 10,\n\
            borderWidth: 1,\n\
            type: 'line'\n\
          },\n\
          lang: {\n\
            loading: 'Chargement...',\n\
            months: ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],\n\
            weekdays: ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'],\n\
            shortMonths: ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'aoû', 'sep', 'oct', 'nov', 'déc'],\n\
            exportButtonTitle: \"Exporter\",\n\
            printButtonTitle: \"Imprimer\",\n\
            rangeSelectorFrom: \"Du\",\n\
            rangeSelectorTo: \"au\",\n\
            rangeSelectorZoom: \"Période\",\n\
            downloadPNG: 'Télécharger en PNG',\n\
            downloadJPEG: 'Télécharger en JPEG',\n\
            downloadPDF: 'Télécharger en PDF',\n\
            downloadSVG: 'Télécharger en SVG',\n\
            resetZoom: \"Réinitialiser le zoom\",\n\
            resetZoomTitle: \"Réinitialiser le zoom\",\n\
            thousandsSep: \" \",\n\
            decimalPoint: ',' \n\
        },\n\
          credits: {\n\
            enabled: false\n\
          },\n\
          title: {\n\
            text: '" + name_chart.upper() + "'\n\
          },\n\
          xAxis: {\n\
            type: 'datetime'\n\
          },\n\
          yAxis: {\n\
            title: {\n\
              text: ''\n\
            }\n\
          },\
          legend: {\n\
            enabled: false\n\
          },\n\
          plotOptions: {\n\
            area: {\n\
              fillColor: {\n\
                linearGradient: {\n\
                  x1: 0,\n\
                  y1: 0,\n\
                  x2: 0,\n\
                  y2: 1\n\
                },\n\
                stops: [\n\
                  [0, Highcharts.getOptions().colors[0]],\n\
                  [1, Highcharts.color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]\n\
                ]\n\
              },\n\
              marker: {\n\
                radius: 2\n\
              },\n\
              lineWidth: 1,\n\
              states: {\n\
                hover: {\n\
                  lineWidth: 1\n\
                }\n\
              },\n\
              threshold: null\n\
            }\n\
          },\n\
          series: [{\n\
            type: 'area',\n\
            name: 'VALUE',\n\
            data: data\n\
          }]\n\
        });\n\
      }\n\
    );\n</script>\n"
    print("\n\n##" + str(rdd_prev) + "##\n\n")
    with open(sys.path[0]+"/templates/dashboard.html", 'w') as prodHTML:
        page += "  </tbody></table>\n</div>" + rdd_prev + "</div>\n" + include.footer
        prodHTML.write(page)
    return render_template("dashboard.html")

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

app.run(host="0.0.0.0", port=80)
