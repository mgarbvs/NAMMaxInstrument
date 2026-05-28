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
      100.0,
      100.0,
      620.0,
      260.0
    ],
    "bglocked": 0,
    "openinpresentation": 0,
    "boxes": [
      {
        "box": {
          "id": "hdr",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "outlettype": [],
          "patching_rect": [
            5,
            3,
            580,
            20
          ],
          "text": "Push 3 parameter_visibility test (Live 12.4). Check Max console."
        }
      },
      {
        "box": {
          "id": "hdr2",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "outlettype": [],
          "patching_rect": [
            5,
            22,
            580,
            20
          ],
          "text": "Push should show F_Vis / G_VNS / H_PE0. Click buttons to update Pre->Alpha."
        }
      },
      {
        "box": {
          "id": "testmenu_f",
          "maxclass": "live.menu",
          "varname": "testmenu_f",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "int",
            "bang"
          ],
          "patching_rect": [
            5,
            45,
            90,
            22
          ],
          "parameter_enable": 1,
          "hidden": 0,
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "F_Vis",
              "parameter_shortname": "F_Vis",
              "parameter_type": 2,
              "parameter_enum": [
                "Pre-0",
                "Pre-1",
                "Pre-2",
                "Pre-3",
                "Pre-4"
              ],
              "parameter_initial_enable": 1,
              "parameter_initial": [
                0
              ],
              "parameter_visibility": "Visible"
            }
          }
        }
      },
      {
        "box": {
          "id": "testmenu_g",
          "maxclass": "live.menu",
          "varname": "testmenu_g",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "int",
            "bang"
          ],
          "patching_rect": [
            105,
            45,
            90,
            22
          ],
          "parameter_enable": 1,
          "hidden": 0,
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "G_VNS",
              "parameter_shortname": "G_VNS",
              "parameter_type": 2,
              "parameter_enum": [
                "Pre-0",
                "Pre-1",
                "Pre-2",
                "Pre-3",
                "Pre-4"
              ],
              "parameter_initial_enable": 1,
              "parameter_initial": [
                0
              ],
              "parameter_visibility": "Visible (Not Stored)"
            }
          }
        }
      },
      {
        "box": {
          "id": "testmenu_h",
          "maxclass": "live.menu",
          "varname": "testmenu_h",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "int",
            "bang"
          ],
          "patching_rect": [
            205,
            45,
            90,
            22
          ],
          "parameter_enable": 0,
          "hidden": 0,
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "H_PE0",
              "parameter_shortname": "H_PE0",
              "parameter_type": 2,
              "parameter_enum": [
                "Pre-0",
                "Pre-1",
                "Pre-2",
                "Pre-3",
                "Pre-4"
              ],
              "parameter_initial_enable": 1,
              "parameter_initial": [
                0
              ],
              "parameter_visibility": "Visible"
            }
          }
        }
      },
      {
        "box": {
          "id": "btn_f",
          "maxclass": "button",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            5,
            75,
            30,
            30
          ]
        }
      },
      {
        "box": {
          "id": "btn_g",
          "maxclass": "button",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            60,
            75,
            30,
            30
          ]
        }
      },
      {
        "box": {
          "id": "btn_h",
          "maxclass": "button",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            115,
            75,
            30,
            30
          ]
        }
      },
      {
        "box": {
          "id": "btn_all",
          "maxclass": "button",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            185,
            75,
            30,
            30
          ]
        }
      },
      {
        "box": {
          "id": "lbl_f",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "outlettype": [],
          "patching_rect": [
            15,
            82,
            20,
            20
          ],
          "text": "F"
        }
      },
      {
        "box": {
          "id": "lbl_g",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "outlettype": [],
          "patching_rect": [
            70,
            82,
            20,
            20
          ],
          "text": "G"
        }
      },
      {
        "box": {
          "id": "lbl_h",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "outlettype": [],
          "patching_rect": [
            125,
            82,
            20,
            20
          ],
          "text": "H"
        }
      },
      {
        "box": {
          "id": "lbl_all",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "outlettype": [],
          "patching_rect": [
            195,
            82,
            28,
            20
          ],
          "text": "All"
        }
      },
      {
        "box": {
          "id": "msg_f",
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            5,
            120,
            160,
            22
          ],
          "text": "test_f"
        }
      },
      {
        "box": {
          "id": "msg_g",
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            5,
            145,
            160,
            22
          ],
          "text": "test_g"
        }
      },
      {
        "box": {
          "id": "msg_h",
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            5,
            170,
            160,
            22
          ],
          "text": "test_h"
        }
      },
      {
        "box": {
          "id": "msg_all",
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            5,
            195,
            160,
            22
          ],
          "text": "test_all"
        }
      },
      {
        "box": {
          "id": "js1",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            5,
            225,
            180,
            22
          ],
          "text": "js testpushenum.js"
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "source": [
            "btn_f",
            0
          ],
          "destination": [
            "msg_f",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "msg_f",
            0
          ],
          "destination": [
            "js1",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "btn_g",
            0
          ],
          "destination": [
            "msg_g",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "msg_g",
            0
          ],
          "destination": [
            "js1",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "btn_h",
            0
          ],
          "destination": [
            "msg_h",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "msg_h",
            0
          ],
          "destination": [
            "js1",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "btn_all",
            0
          ],
          "destination": [
            "msg_all",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "msg_all",
            0
          ],
          "destination": [
            "js1",
            0
          ]
        }
      }
    ]
  }
}