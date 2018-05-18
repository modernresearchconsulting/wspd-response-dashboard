var app = {};

$(document).ready( function() {

  app.map_center_default = {
    lat : 36.094637,
    lng : -80.244023
  };

  app.map_style = [
    {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#e9e9e9",
            },
            {
                "lightness": 17
            }
        ]
    },
    {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [
            {
                "color_original": "#f5f5f5",
                "color": "#e5e5e5"
            },
            {
                "lightness": 20
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 17
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 29
            },
            {
                "weight": 0.2
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 18
            }
        ]
    },
    {
        "featureType": "road.local",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 16
            }
        ]
    },
    {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#f5f5f5",
            },
            {
                "lightness": 21
            }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#dedede",
            },
            {
                "lightness": 21
            }
        ]
    },
    {
        "elementType": "labels.text.stroke",
        "stylers": [
            {
                "visibility": "on"
            },
            {
                "color": "#ffffff",
            },
            {
                "lightness": 16
            }
        ]
    },
    {
        "elementType": "labels.text.fill",
        "stylers": [
            {
                "saturation": 36
            },
            {
                "color": "#666666",
            },
            {
                "lightness": 40
            }
        ]
    },
    {
        "elementType": "labels.icon",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#f2f2f2"
            },
            {
                "lightness": 19
            }
        ]
    },
    {
        "featureType": "administrative",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#fefefe"
            },
            {
                "lightness": 20
            }
        ]
    },
    {
        "featureType": "administrative",
        "elementType": "geometry.stroke",
        "stylers": [
            {
                "color": "#fefefe"
            },
            {
                "lightness": 17
            },
            {
                "weight": 1.2
            }
        ]
    }
];



  Shiny.addCustomMessageHandler('initialize_map', function(message) {
    app[message.div] = new google.maps.Map(
      document.getElementById(message.div),
      {
        center: new google.maps.LatLng(app.map_center_default.lat,
                                       app.map_center_default.lng),
        mapTypeControl  : false,
        mapTypeId     : google.maps.MapTypeId.ROADMAP,
        streetViewControl : false,
        styles      : app.map_style,
        zoom      : 12,
        zoomControlOptions : {
          style : google.maps.ZoomControlStyle.SMALL,
          position : google.maps.ControlPosition.TOP_LEFT
        }
      });

    app.analysis_heatmap = new google.maps.visualization.HeatmapLayer();

    if (message.div === 'alert_map') {

      alert_map_center = new google.maps.LatLng(app.map_center_default.lat,
                                       app.map_center_default.lng);

      app.alert_map_focus = new google.maps.Circle({
        center: alert_map_center,
        map: app.alert_map,
        radius: 1000
      });

      var update_alert_center = function(e) {
        var lat_lng = e.latLng;

        console.log(e.latLng.lat(),
                    e.latLng.lng());

        Shiny.onInputChange('alert_center', e);
      }

      app.alert_map_focus.addListener('click', update_alert_center);
      app.alert_map.addListener('click', update_alert_center);
    }
  });

  Shiny.addCustomMessageHandler('clear_heatmap', function(message) {
    app.analysis_heatmap.setMap(null);
  });

  Shiny.addCustomMessageHandler('draw_heatmap', function(message) {

    var heatmapData = new google.maps.MVCArray()

    for (var i = 0; i < message.latitude.length; i++) {
      heatmapData.push({
        location: new google.maps.LatLng(message.latitude[i],
                                         message.longitude[i]),
        weight: message.weight[i]
      });
    }

    app.analysis_heatmap = new google.maps.visualization.HeatmapLayer({
      data: heatmapData,
      /*gradient: ['rgba(0,0,0,0)', '#ffffd9','#edf8b1','#c7e9b4','#7fcdbb','#41b6c4','#1d91c0','#225ea8','#253494','#081d58'],*/
      /*gradient: ['rgb(255,255,217)','rgb(237,248,177)','rgb(199,233,180)','rgb(127,205,187)','rgb(65,182,196)','rgb(29,145,192)','rgb(34,94,168)','rgb(37,52,148)','rgb(8,29,88)'],*/
      maxIntensity: 10,
      radius: 12
    });

    app.analysis_heatmap.setMap(app.analysis_map);
  })

  Shiny.addCustomMessageHandler('update_alert_map_focus', function(message) {
    console.log('updating alert map focus');
    if (app && app.alert_map) {
      if (message.center) {
        app.alert_map_focus.setCenter(new google.maps.LatLng(
          message.center.lat,
          message.center.lng
        ));
      }

      if (message.radius) {
        app.alert_map_focus.setRadius(message.radius);
      }
    }
  });


});

