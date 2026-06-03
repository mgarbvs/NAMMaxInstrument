{
 "patcher": {
  "fileversion": 1,
  "appversion": {
   "major": 9,
   "minor": 0,
   "revision": 10,
   "architecture": "x64",
   "modernui": 1
  },
  "classnamespace": "box",
  "rect": [
   100,
   100,
   360,
   240
  ],
  "openinpresentation": 1,
  "default_fontsize": 12.0,
  "default_fontname": "Ableton Sans Medium",
  "gridsize": [
   8.0,
   8.0
  ],
  "boxes": [
   {
    "box": {
     "id": "plugin",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      20,
      320,
      60,
      22
     ],
     "text": "plugin~",
     "varname": "plugin"
    }
   },
   {
    "box": {
     "id": "plugout",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      20,
      380,
      60,
      22
     ],
     "text": "plugout~",
     "varname": "plugout"
    }
   },
   {
    "box": {
     "id": "thisdev",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 4,
     "outlettype": [
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      120,
      320,
      110,
      22
     ],
     "text": "live.thisdevice",
     "varname": "thisdev"
    }
   },
   {
    "box": {
     "id": "lbl_text",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      220,
      80,
      18
     ],
     "presentation": 1,
     "presentation_rect": [
      20,
      20,
      80,
      18
     ],
     "text": "live.text enum",
     "fontsize": 9,
     "varname": "lbl_text"
    }
   },
   {
    "box": {
     "id": "disc_text",
     "maxclass": "live.text",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      20,
      240,
      80,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      20,
      40,
      80,
      22
     ],
     "parameter_enable": 1,
     "mode": 1,
     "text": "Off",
     "texton": "On",
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Disc Text",
       "parameter_shortname": "Text",
       "parameter_type": 2,
       "parameter_enum": [
        "Off",
        "On"
       ],
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ]
      }
     },
     "varname": "disc_text"
    }
   },
   {
    "box": {
     "id": "lbl_menu",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      120,
      220,
      80,
      18
     ],
     "presentation": 1,
     "presentation_rect": [
      120,
      20,
      80,
      18
     ],
     "text": "live.menu enum",
     "fontsize": 9,
     "varname": "lbl_menu"
    }
   },
   {
    "box": {
     "id": "disc_menu",
     "maxclass": "live.menu",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "bang"
     ],
     "patching_rect": [
      120,
      240,
      80,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      120,
      40,
      80,
      22
     ],
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Disc Menu",
       "parameter_shortname": "Menu",
       "parameter_type": 2,
       "parameter_enum": [
        "Off",
        "On"
       ],
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ]
      }
     },
     "varname": "disc_menu"
    }
   },
   {
    "box": {
     "id": "lbl_bool",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      220,
      220,
      80,
      18
     ],
     "presentation": 1,
     "presentation_rect": [
      220,
      20,
      80,
      18
     ],
     "text": "live.toggle bool",
     "fontsize": 9,
     "varname": "lbl_bool"
    }
   },
   {
    "box": {
     "id": "disc_bool",
     "maxclass": "live.toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      220,
      240,
      24,
      24
     ],
     "presentation": 1,
     "presentation_rect": [
      220,
      40,
      24,
      24
     ],
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Disc Bool",
       "parameter_shortname": "Bool",
       "parameter_type": 1,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ]
      }
     },
     "varname": "disc_bool"
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "source": [
      "plugin",
      0
     ],
     "destination": [
      "plugout",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "plugin",
      1
     ],
     "destination": [
      "plugout",
      1
     ]
    }
   }
  ],
  "parameters": {
   "disc_text": [
    "Disc Text",
    "Text",
    0
   ],
   "disc_menu": [
    "Disc Menu",
    "Menu",
    0
   ],
   "disc_bool": [
    "Disc Bool",
    "Bool",
    0
   ],
   "parameterbanks": {
    "0": {
     "index": 0,
     "name": "Discrim",
     "parameters": [
      "Disc Text",
      "Disc Menu",
      "Disc Bool",
      "-",
      "-",
      "-",
      "-",
      "-"
     ],
     "buttons": [
      "-",
      "-",
      "-",
      "-",
      "-",
      "-",
      "-",
      "-"
     ]
    }
   },
   "inherited_shortname": 1
  }
 }
}