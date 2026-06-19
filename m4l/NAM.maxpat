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
			1400.0,
			800.0
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
					"id": "thisdev",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"bang",
						"int",
						"int"
					],
					"patching_rect": [
						30,
						30,
						110,
						22
					],
					"text": "live.thisdevice",
					"varname": "thisdev"
				}
			},
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
						30,
						60,
						80,
						22
					],
					"text": "plugin~"
				}
			},
			{
				"box": {
					"id": "plugout",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						30,
						700,
						80,
						22
					],
					"text": "plugout~"
				}
			},
			{
				"box": {
					"id": "sum_lr",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						30,
						90,
						40,
						22
					],
					"text": "+~",
					"varname": "sum_lr"
				}
			},
			{
				"box": {
					"id": "half",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						30,
						116,
						60,
						22
					],
					"text": "*~ 0.5",
					"varname": "half"
				}
			},
			{
				"box": {
					"id": "in_gain",
					"maxclass": "live.gain~",
					"numinlets": 2,
					"numoutlets": 5,
					"outlettype": [
						"signal",
						"signal",
						"float",
						"float",
						"list"
					],
					"patching_rect": [
						1102,
						405,
						55,
						90
					],
					"presentation": 1,
					"presentation_rect": [
						2,
						5,
						55,
						90
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Input",
							"parameter_shortname": "In",
							"parameter_type": 0,
							"parameter_unitstyle": 4,
							"parameter_mmin": -36.0,
							"parameter_mmax": 36.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0.0
							]
						}
					},
					"varname": "in_gain"
				}
			},
			{
				"box": {
					"id": "out_gain",
					"maxclass": "live.gain~",
					"numinlets": 2,
					"numoutlets": 5,
					"outlettype": [
						"signal",
						"signal",
						"float",
						"float",
						"list"
					],
					"patching_rect": [
						1363,
						405,
						55,
						90
					],
					"presentation": 1,
					"presentation_rect": [
						263,
						5,
						55,
						90
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Out",
							"parameter_shortname": "Out",
							"parameter_type": 0,
							"parameter_unitstyle": 4,
							"parameter_mmin": -36.0,
							"parameter_mmax": 36.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0.0
							]
						}
					},
					"varname": "out_gain"
				}
			},
			{
				"box": {
					"id": "nodestate",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						300,
						30,
						280,
						22
					],
					"text": "node.script nam_state.js @autostart 1",
					"varname": "nodestate"
				}
			},
			{
				"box": {
					"id": "jsloader",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 8,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						300,
						60,
						160,
						22
					],
					"text": "js nam_loader.js",
					"varname": "jsloader"
				}
			},
			{
				"box": {
					"id": "pre_rehydrate",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300,
						6,
						160,
						22
					],
					"text": "prepend rehydrate",
					"varname": "pre_rehydrate"
				}
			},
			{
				"box": {
					"id": "delay_startup",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						480,
						6,
						80,
						22
					],
					"text": "delay 1000",
					"varname": "delay_startup"
				}
			},
			{
				"box": {
					"id": "msg_getall",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						570,
						6,
						100,
						22
					],
					"text": "get_all",
					"varname": "msg_getall"
				}
			},
			{
				"box": {
					"id": "pre_sr_changed",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						6,
						140,
						22
					],
					"text": "prepend sr_changed",
					"varname": "pre_sr_changed"
				}
			},
			{
				"box": {
					"id": "nam_ext",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"signal",
						"",
						"bang",
						"symbol"
					],
					"patching_rect": [
						30,
						160,
						60,
						22
					],
					"text": "nam~",
					"varname": "nam_ext"
				}
			},
			{
				"box": {
					"id": "print_nam_meta",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": [],
					"patching_rect": [
						200,
						160,
						140,
						22
					],
					"text": "print nam_meta",
					"varname": "print_nam_meta"
				}
			},
			{
				"box": {
					"id": "status_msg",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1110,
						488,
						300,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						62,
						8,
						196,
						18
					],
					"text": "(no model loaded)",
					"varname": "status_msg"
				}
			},
			{
				"box": {
					"id": "msg_nam_loaded",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30,
						186,
						130,
						22
					],
					"text": "set Loaded",
					"varname": "msg_nam_loaded"
				}
			},
			{
				"box": {
					"id": "pre_nam_error",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170,
						186,
						100,
						22
					],
					"text": "prepend set",
					"varname": "pre_nam_error"
				}
			},
			{
				"box": {
					"id": "bypass_dry_delay",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						1000,
						116,
						140,
						22
					],
					"text": "delay~ 96000 0",
					"varname": "bypass_dry_delay"
				}
			},
			{
				"box": {
					"id": "bypass_sel",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						1000,
						160,
						100,
						22
					],
					"text": "selector~ 2",
					"varname": "bypass_sel"
				}
			},
			{
				"box": {
					"id": "bypass_toggle",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1260,
						544,
						58,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						160,
						144,
						58,
						22
					],
					"parameter_enable": 1,
					"mode": 1,
					"text": "Bypass",
					"texton": "Bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Bypass",
							"parameter_shortname": "Byp",
							"parameter_type": 2,
							"parameter_enum": [
								"off",
								"on"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "bypass_toggle"
				}
			},
			{
				"box": {
					"id": "tone_expand_toggle",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1322,
						544,
						46,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						222,
						144,
						46,
						22
					],
					"parameter_enable": 1,
					"mode": 1,
					"text": "Tone",
					"texton": "Tone",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Tone Section",
							"parameter_shortname": "Tone",
							"parameter_type": 2,
							"parameter_enum": [
								"collapsed",
								"expanded"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								1
							]
						}
					},
					"varname": "tone_expand_toggle"
				}
			},
			{
				"box": {
					"id": "ir_expand_toggle",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1372,
						544,
						48,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						272,
						144,
						48,
						22
					],
					"parameter_enable": 1,
					"mode": 1,
					"text": "IR",
					"texton": "IR",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Section",
							"parameter_shortname": "IR",
							"parameter_type": 2,
							"parameter_enum": [
								"collapsed",
								"expanded"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								1
							]
						}
					},
					"varname": "ir_expand_toggle"
				}
			},
			{
				"box": {
					"id": "collapse_tp",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						1100,
						6,
						80,
						22
					],
					"text": "thispatcher",
					"varname": "collapse_tp"
				}
			},
			{
				"box": {
					"id": "collapse_js",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						1100,
						35,
						160,
						22
					],
					"text": "js nam_collapse.js",
					"varname": "collapse_js"
				}
			},
			{
				"box": {
					"id": "bypass_plus1",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1010,
						200,
						40,
						22
					],
					"text": "+ 1",
					"varname": "bypass_plus1"
				}
			},
			{
				"box": {
					"id": "btn_nam_root",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1100,
						544,
						100,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						144,
						100,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": "Set NAM Root",
					"texton": "Set NAM Root",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Set NAM Root",
							"parameter_shortname": "NAMRoot",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "btn_nam_root"
				}
			},
			{
				"box": {
					"id": "opendlg_nam",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"symbol"
					],
					"patching_rect": [
						500,
						186,
						110,
						22
					],
					"text": "opendialog folder",
					"varname": "opendlg_nam"
				}
			},
			{
				"box": {
					"id": "pattr_nam_root",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						500,
						212,
						200,
						22
					],
					"text": "pattr nam_root @autorestore 1 @type symbol",
					"varname": "pattr_nam_root"
				}
			},
			{
				"box": {
					"id": "pattr_nam_relpath",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						500,
						238,
						200,
						22
					],
					"text": "pattr nam_relpath @autorestore 1 @type symbol",
					"varname": "pattr_nam_relpath"
				}
			},
			{
				"box": {
					"id": "pre_nam_root",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500,
						264,
						160,
						22
					],
					"text": "prepend set_nam_root",
					"varname": "pre_nam_root"
				}
			},
			{
				"box": {
					"id": "rcv_set_nam_relpath",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						750,
						212,
						260,
						22
					],
					"text": "receive nam_state_set_nam_relpath",
					"varname": "rcv_set_nam_relpath"
				}
			},
			{
				"box": {
					"id": "pre_set_nam_relpath",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						750,
						238,
						190,
						22
					],
					"text": "prepend set_nam_relpath",
					"varname": "pre_set_nam_relpath"
				}
			},
			{
				"box": {
					"id": "trim_pfx_toggle_nam",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1204,
						548,
						14,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						104,
						148,
						14,
						14
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Trim Prefix",
							"parameter_shortname": "TrimNAM",
							"parameter_type": 1,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								1
							]
						}
					},
					"varname": "trim_pfx_toggle_nam"
				}
			},
			{
				"box": {
					"id": "lbl_trim_nam",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1221,
						548,
						36,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						121,
						148,
						36,
						14
					],
					"text": "Trim",
					"fontsize": 9,
					"varname": "lbl_trim_nam"
				}
			},
			{
				"box": {
					"id": "pre_trim_nam",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500,
						290,
						200,
						22
					],
					"text": "prepend set_trim_prefix_nam",
					"varname": "pre_trim_nam"
				}
			},
			{
				"box": {
					"id": "nam_cat_menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						300,
						320,
						276,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						22,
						100,
						276,
						22
					],
					"varname": "nam_cat_menu"
				}
			},
			{
				"box": {
					"id": "nam_model_menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						300,
						346,
						276,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						22,
						122,
						276,
						22
					],
					"varname": "nam_model_menu"
				}
			},
			{
				"box": {
					"id": "pre_sel_nam_cat",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300,
						372,
						210,
						22
					],
					"text": "prepend select_nam_category",
					"varname": "pre_sel_nam_cat"
				}
			},
			{
				"box": {
					"id": "pre_sel_nam_model",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						300,
						398,
						200,
						22
					],
					"text": "prepend select_nam_model",
					"varname": "pre_sel_nam_model"
				}
			},
			{
				"box": {
					"id": "btn_cat_prev",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1100,
						500,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						100,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": "<",
					"texton": "<",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Cat Prev",
							"parameter_shortname": "CatPrev",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_cat_prev"
				}
			},
			{
				"box": {
					"id": "pre_btn_cat_prev",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500,
						424,
						150,
						22
					],
					"text": "prepend prev_cat",
					"varname": "pre_btn_cat_prev"
				}
			},
			{
				"box": {
					"id": "btn_cat_next",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1398,
						500,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						298,
						100,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": ">",
					"texton": ">",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Cat Next",
							"parameter_shortname": "CatNext",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_cat_next"
				}
			},
			{
				"box": {
					"id": "pre_btn_cat_next",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						798,
						424,
						150,
						22
					],
					"text": "prepend next_cat",
					"varname": "pre_btn_cat_next"
				}
			},
			{
				"box": {
					"id": "btn_model_prev",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1100,
						522,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						122,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": "<",
					"texton": "<",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Model Prev",
							"parameter_shortname": "ModPrev",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_model_prev"
				}
			},
			{
				"box": {
					"id": "pre_btn_model_prev",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500,
						424,
						150,
						22
					],
					"text": "prepend prev_model",
					"varname": "pre_btn_model_prev"
				}
			},
			{
				"box": {
					"id": "btn_model_next",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1398,
						522,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						298,
						122,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": ">",
					"texton": ">",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Model Next",
							"parameter_shortname": "ModNext",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_model_next"
				}
			},
			{
				"box": {
					"id": "pre_btn_model_next",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						798,
						424,
						150,
						22
					],
					"text": "prepend next_model",
					"varname": "pre_btn_model_next"
				}
			},
			{
				"box": {
					"id": "nam_cat_idx",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						940,
						320,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Cat",
							"parameter_shortname": "NamCat",
							"parameter_type": 2,
							"parameter_enum": [
								"1",
								"2",
								"3",
								"4",
								"5",
								"6",
								"7",
								"8",
								"9",
								"10",
								"11",
								"12",
								"13",
								"14",
								"15",
								"16",
								"17",
								"18",
								"19",
								"20",
								"21",
								"22",
								"23",
								"24",
								"25",
								"26",
								"27",
								"28",
								"29",
								"30",
								"31",
								"32",
								"33",
								"34",
								"35",
								"36",
								"37",
								"38",
								"39",
								"40",
								"41",
								"42",
								"43",
								"44",
								"45",
								"46",
								"47",
								"48",
								"49",
								"50",
								"51",
								"52",
								"53",
								"54",
								"55",
								"56",
								"57",
								"58",
								"59",
								"60",
								"61",
								"62",
								"63",
								"64",
								"65",
								"66",
								"67",
								"68",
								"69",
								"70",
								"71",
								"72",
								"73",
								"74",
								"75",
								"76",
								"77",
								"78",
								"79",
								"80",
								"81",
								"82",
								"83",
								"84",
								"85",
								"86",
								"87",
								"88",
								"89",
								"90",
								"91",
								"92",
								"93",
								"94",
								"95",
								"96",
								"97",
								"98",
								"99",
								"100"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "nam_cat_idx"
				}
			},
			{
				"box": {
					"id": "pre_push_nam_cat_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						940,
						348,
						250,
						22
					],
					"text": "prepend select_nam_cat_by_push",
					"varname": "pre_push_nam_cat_idx"
				}
			},
			{
				"box": {
					"id": "rcv_set_nam_cat_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						320,
						210,
						22
					],
					"text": "receive nam_numbox_set_cat",
					"varname": "rcv_set_nam_cat_idx"
				}
			},
			{
				"box": {
					"id": "pre_set_nam_cat_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						348,
						80,
						22
					],
					"text": "prepend set",
					"varname": "pre_set_nam_cat_idx"
				}
			},
			{
				"box": {
					"id": "nam_model_idx",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						940,
						346,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Model",
							"parameter_shortname": "Model",
							"parameter_type": 2,
							"parameter_enum": [
								"1",
								"2",
								"3",
								"4",
								"5",
								"6",
								"7",
								"8",
								"9",
								"10",
								"11",
								"12",
								"13",
								"14",
								"15",
								"16",
								"17",
								"18",
								"19",
								"20",
								"21",
								"22",
								"23",
								"24",
								"25",
								"26",
								"27",
								"28",
								"29",
								"30",
								"31",
								"32",
								"33",
								"34",
								"35",
								"36",
								"37",
								"38",
								"39",
								"40",
								"41",
								"42",
								"43",
								"44",
								"45",
								"46",
								"47",
								"48",
								"49",
								"50",
								"51",
								"52",
								"53",
								"54",
								"55",
								"56",
								"57",
								"58",
								"59",
								"60",
								"61",
								"62",
								"63",
								"64",
								"65",
								"66",
								"67",
								"68",
								"69",
								"70",
								"71",
								"72",
								"73",
								"74",
								"75",
								"76",
								"77",
								"78",
								"79",
								"80",
								"81",
								"82",
								"83",
								"84",
								"85",
								"86",
								"87",
								"88",
								"89",
								"90",
								"91",
								"92",
								"93",
								"94",
								"95",
								"96",
								"97",
								"98",
								"99",
								"100"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "nam_model_idx"
				}
			},
			{
				"box": {
					"id": "pre_push_nam_model_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						940,
						374,
						250,
						22
					],
					"text": "prepend select_nam_model_by_push",
					"varname": "pre_push_nam_model_idx"
				}
			},
			{
				"box": {
					"id": "rcv_set_nam_model_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						346,
						210,
						22
					],
					"text": "receive nam_numbox_set_model",
					"varname": "rcv_set_nam_model_idx"
				}
			},
			{
				"box": {
					"id": "pre_set_nam_model_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						374,
						80,
						22
					],
					"text": "prepend set",
					"varname": "pre_set_nam_model_idx"
				}
			},
			{
				"box": {
					"id": "nam_live_drop",
					"maxclass": "live.drop",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						1157,
						400,
						206,
						100
					],
					"presentation": 1,
					"presentation_rect": [
						57,
						0,
						206,
						100
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Drop",
							"parameter_shortname": "Drop",
							"parameter_type": 4
						}
					},
					"varname": "nam_live_drop"
				}
			},
			{
				"box": {
					"id": "pre_drop_nam",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						500,
						450,
						200,
						22
					],
					"text": "prepend load_dropped_nam",
					"varname": "pre_drop_nam"
				}
			},
			{
				"box": {
					"id": "amp_fpic",
					"maxclass": "fpic",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1157,
						400,
						206,
						100
					],
					"presentation": 1,
					"presentation_rect": [
						57,
						0,
						206,
						100
					],
					"pic": "amp_grill.png",
					"varname": "amp_fpic"
				}
			},
			{
				"box": {
					"id": "ng_trigger",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"signal",
						"signal"
					],
					"patching_rect": [
						130,
						220,
						130,
						22
					],
					"text": "namgate_trigger~",
					"varname": "ng_trigger"
				}
			},
			{
				"box": {
					"id": "ng_gain",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						30,
						250,
						110,
						22
					],
					"text": "namgate_gain~",
					"varname": "ng_gain"
				}
			},
			{
				"box": {
					"id": "gate_sel",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						30,
						280,
						100,
						22
					],
					"text": "selector~ 2",
					"varname": "gate_sel"
				}
			},
			{
				"box": {
					"id": "gate_thresh_dial",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						1474,
						492,
						50,
						52
					],
					"presentation": 1,
					"presentation_rect": [
						374,
						92,
						50,
						52
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Noise Gate Threshold",
							"parameter_shortname": "Gate",
							"parameter_type": 0,
							"parameter_mmin": -70.0,
							"parameter_mmax": 0.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								-70.0
							],
							"parameter_unitstyle": 4,
							"parameter_modmode": 1
						}
					},
					"varname": "gate_thresh_dial"
				}
			},
			{
				"box": {
					"id": "pre_gate_thresh",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200,
						280,
						150,
						22
					],
					"text": "prepend threshold",
					"varname": "pre_gate_thresh"
				}
			},
			{
				"box": {
					"id": "gate_on_toggle",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1420,
						544,
						160,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						320,
						144,
						160,
						22
					],
					"parameter_enable": 1,
					"mode": 1,
					"text": "Gate off",
					"texton": "Gate on",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Noise Gate On",
							"parameter_shortname": "GateOn",
							"parameter_type": 2,
							"parameter_enum": [
								"Gate off",
								"Gate on"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "gate_on_toggle"
				}
			},
			{
				"box": {
					"id": "gate_on_plus1",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						30,
						306,
						40,
						22
					],
					"text": "+ 1",
					"varname": "gate_on_plus1"
				}
			},
			{
				"box": {
					"id": "nam_blend_dial",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						1420,
						492,
						50,
						52
					],
					"presentation": 1,
					"presentation_rect": [
						320,
						92,
						50,
						52
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Dry/Wet",
							"parameter_shortname": "NAM",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 100.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								100.0
							],
							"parameter_unitstyle": 5,
							"parameter_modmode": 0
						}
					},
					"varname": "nam_blend_dial"
				}
			},
			{
				"box": {
					"id": "nam_blend_div",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						30,
						328,
						60,
						22
					],
					"text": "/ 100.",
					"varname": "nam_blend_div"
				}
			},
			{
				"box": {
					"id": "nam_blend_inv",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						100,
						328,
						120,
						22
					],
					"text": "expr 1. - $f1",
					"varname": "nam_blend_inv"
				}
			},
			{
				"box": {
					"id": "nam_dry_mul",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						30,
						354,
						40,
						22
					],
					"text": "*~",
					"varname": "nam_dry_mul"
				}
			},
			{
				"box": {
					"id": "nam_wet_mul",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						80,
						354,
						40,
						22
					],
					"text": "*~",
					"varname": "nam_wet_mul"
				}
			},
			{
				"box": {
					"id": "nam_blend_sum",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						50,
						380,
						40,
						22
					],
					"text": "+~",
					"varname": "nam_blend_sum"
				}
			},
			{
				"box": {
					"id": "eq_curve_jsui",
					"maxclass": "jsui",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1420,
						400,
						320,
						90
					],
					"presentation": 1,
					"presentation_rect": [
						320,
						0,
						320,
						90
					],
					"filename": "eq_curve.jsui",
					"varname": "eq_curve_jsui"
				}
			},
			{
				"box": {
					"id": "tone_ext",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"signal",
						""
					],
					"patching_rect": [
						30,
						360,
						80,
						22
					],
					"text": "namtone~",
					"varname": "tone_ext"
				}
			},
			{
				"box": {
					"id": "tone_sel",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						30,
						390,
						100,
						22
					],
					"text": "selector~ 2",
					"varname": "tone_sel"
				}
			},
			{
				"box": {
					"id": "bass_dial",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						1528,
						492,
						50,
						52
					],
					"presentation": 1,
					"presentation_rect": [
						428,
						92,
						50,
						52
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Bass",
							"parameter_shortname": "Bass",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 10.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								5.0
							],
							"parameter_unitstyle": 1,
							"parameter_modmode": 2,
							"parameter_steps": 1001
						}
					},
					"varname": "bass_dial"
				}
			},
			{
				"box": {
					"id": "mid_dial",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						1582,
						492,
						50,
						52
					],
					"presentation": 1,
					"presentation_rect": [
						482,
						92,
						50,
						52
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Mid",
							"parameter_shortname": "Mid",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 10.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								5.0
							],
							"parameter_unitstyle": 1,
							"parameter_modmode": 2,
							"parameter_steps": 1001
						}
					},
					"varname": "mid_dial"
				}
			},
			{
				"box": {
					"id": "treble_dial",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						1636,
						492,
						50,
						52
					],
					"presentation": 1,
					"presentation_rect": [
						536,
						92,
						50,
						52
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Treble",
							"parameter_shortname": "Trbl",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 10.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								5.0
							],
							"parameter_unitstyle": 1,
							"parameter_modmode": 2,
							"parameter_steps": 1001
						}
					},
					"varname": "treble_dial"
				}
			},
			{
				"box": {
					"id": "pre_bass",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						200,
						360,
						110,
						22
					],
					"text": "prepend bass",
					"varname": "pre_bass"
				}
			},
			{
				"box": {
					"id": "pre_mid",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						230,
						360,
						110,
						22
					],
					"text": "prepend mid",
					"varname": "pre_mid"
				}
			},
			{
				"box": {
					"id": "pre_treble",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						260,
						360,
						110,
						22
					],
					"text": "prepend treble",
					"varname": "pre_treble"
				}
			},
			{
				"box": {
					"id": "tone_on_toggle",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1580,
						544,
						160,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						480,
						144,
						160,
						22
					],
					"parameter_enable": 1,
					"mode": 1,
					"text": "Tone off",
					"texton": "Tone on",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Tone Stack On",
							"parameter_shortname": "EQOn",
							"parameter_type": 2,
							"parameter_enum": [
								"Tone off",
								"Tone on"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								1
							]
						}
					},
					"varname": "tone_on_toggle"
				}
			},
			{
				"box": {
					"id": "tonestack_on_plus1",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						30,
						416,
						40,
						22
					],
					"text": "+ 1",
					"varname": "tonestack_on_plus1"
				}
			},
			{
				"box": {
					"id": "ir_buf",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"float",
						"bang"
					],
					"patching_rect": [
						600,
						80,
						120,
						22
					],
					"text": "buffer~ ir_buf",
					"varname": "ir_buf"
				}
			},
			{
				"box": {
					"id": "ir_display_buf",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						600,
						110,
						140,
						22
					],
					"text": "buffer~ ir_display 1",
					"varname": "ir_display_buf"
				}
			},
			{
				"box": {
					"id": "irdisplay_obj",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						600,
						140,
						80,
						22
					],
					"text": "irdisplay~",
					"varname": "irdisplay_obj"
				}
			},
			{
				"box": {
					"id": "msg_irdisplay_process",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						750,
						110,
						200,
						22
					],
					"text": "process ir_display ir_buf",
					"varname": "msg_irdisplay_process"
				}
			},
			{
				"box": {
					"id": "msg_set_waveform_display",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						170,
						140,
						22
					],
					"text": "set ir_display",
					"varname": "msg_set_waveform_display"
				}
			},
			{
				"box": {
					"id": "lb_irconv",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						760,
						80,
						70,
						22
					],
					"text": "loadbang",
					"varname": "lb_irconv"
				}
			},
			{
				"box": {
					"id": "msg_set_ir",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						760,
						104,
						130,
						22
					],
					"text": "set ir_buf",
					"varname": "msg_set_ir"
				}
			},
			{
				"box": {
					"id": "mconv",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 4,
					"outlettype": [
						"signal",
						"",
						"bang",
						"symbol"
					],
					"patching_rect": [
						600,
						200,
						80,
						22
					],
					"text": "irconv~",
					"varname": "mconv"
				}
			},
			{
				"box": {
					"id": "ir_blend_dial",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"patching_rect": [
						1690,
						492,
						50,
						52
					],
					"presentation": 1,
					"presentation_rect": [
						590,
						92,
						50,
						52
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Dry/Wet",
							"parameter_shortname": "IR",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 100.0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								100.0
							],
							"parameter_unitstyle": 5,
							"parameter_modmode": 0
						}
					},
					"varname": "ir_blend_dial"
				}
			},
			{
				"box": {
					"id": "ir_blend_dry_delay",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						820,
						200,
						140,
						22
					],
					"text": "delay~ 96000 0",
					"varname": "ir_blend_dry_delay"
				}
			},
			{
				"box": {
					"id": "ir_blend_div",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						700,
						238,
						60,
						22
					],
					"text": "/ 100.",
					"varname": "ir_blend_div"
				}
			},
			{
				"box": {
					"id": "ir_blend_inv",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						770,
						238,
						120,
						22
					],
					"text": "expr 1. - $f1",
					"varname": "ir_blend_inv"
				}
			},
			{
				"box": {
					"id": "ir_dry_mul",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						700,
						264,
						40,
						22
					],
					"text": "*~",
					"varname": "ir_dry_mul"
				}
			},
			{
				"box": {
					"id": "ir_wet_mul",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						750,
						264,
						40,
						22
					],
					"text": "*~",
					"varname": "ir_wet_mul"
				}
			},
			{
				"box": {
					"id": "ir_blend_sum",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						720,
						290,
						40,
						22
					],
					"text": "+~",
					"varname": "ir_blend_sum"
				}
			},
			{
				"box": {
					"id": "ir_norm",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						700,
						270,
						40,
						22
					],
					"text": "*~",
					"varname": "ir_norm"
				}
			},
			{
				"box": {
					"id": "ir_sel",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"outlettype": [
						"signal"
					],
					"patching_rect": [
						600,
						270,
						100,
						22
					],
					"text": "selector~ 2",
					"varname": "ir_sel"
				}
			},
			{
				"box": {
					"id": "ir_on_toggle",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1894,
						544,
						168,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						794,
						144,
						168,
						22
					],
					"parameter_enable": 1,
					"mode": 1,
					"text": "IR off",
					"texton": "IR on",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR On",
							"parameter_shortname": "IROn",
							"parameter_type": 2,
							"parameter_enum": [
								"IR off",
								"IR on"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								1
							]
						}
					},
					"varname": "ir_on_toggle"
				}
			},
			{
				"box": {
					"id": "ir_on_plus1",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						510,
						250,
						40,
						22
					],
					"text": "+ 1",
					"varname": "ir_on_plus1"
				}
			},
			{
				"box": {
					"id": "route_latency",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						900,
						200,
						100,
						22
					],
					"text": "route latency",
					"varname": "route_latency"
				}
			},
			{
				"box": {
					"id": "unpack_lat",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						900,
						226,
						70,
						22
					],
					"text": "unpack i",
					"varname": "unpack_lat"
				}
			},
			{
				"box": {
					"id": "lat_trig",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"int",
						"int"
					],
					"patching_rect": [
						600,
						300,
						70,
						22
					],
					"text": "t i i i",
					"varname": "lat_trig"
				}
			},
			{
				"box": {
					"id": "msg_latency",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700,
						300,
						140,
						22
					],
					"text": "latency $1",
					"varname": "msg_latency"
				}
			},
			{
				"box": {
					"id": "lat_defer",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700,
						326,
						60,
						22
					],
					"text": "defer",
					"varname": "lat_defer"
				}
			},
			{
				"box": {
					"id": "route_read_sfinfo",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						960,
						80,
						80,
						22
					],
					"text": "route read",
					"varname": "route_read_sfinfo"
				}
			},
			{
				"box": {
					"id": "pre_open_sfinfo",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						960,
						110,
						100,
						22
					],
					"text": "prepend open",
					"varname": "pre_open_sfinfo"
				}
			},
			{
				"box": {
					"id": "sfinfo_dur",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 6,
					"outlettype": [
						"int",
						"int",
						"int",
						"float",
						"",
						"symbol"
					],
					"patching_rect": [
						960,
						140,
						60,
						22
					],
					"text": "sfinfo~",
					"varname": "sfinfo_dur"
				}
			},
			{
				"box": {
					"id": "div_ms",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"float"
					],
					"patching_rect": [
						960,
						170,
						60,
						22
					],
					"text": "/ 1000.",
					"varname": "div_ms"
				}
			},
			{
				"box": {
					"id": "sprintf_dur",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"symbol"
					],
					"patching_rect": [
						960,
						200,
						140,
						22
					],
					"text": "sprintf %.2f sec",
					"varname": "sprintf_dur"
				}
			},
			{
				"box": {
					"id": "pre_set_dur",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						960,
						226,
						100,
						22
					],
					"text": "prepend set",
					"varname": "pre_set_dur"
				}
			},
			{
				"box": {
					"id": "dur_display",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1744,
						402,
						62,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						644,
						2,
						62,
						14
					],
					"text": "",
					"fontsize": 9,
					"varname": "dur_display"
				}
			},
			{
				"box": {
					"id": "btn_ir_root",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1742,
						544,
						100,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						642,
						144,
						100,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": "Set IR Root",
					"texton": "Set IR Root",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Set IR Root",
							"parameter_shortname": "IRRoot",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "btn_ir_root"
				}
			},
			{
				"box": {
					"id": "opendlg_ir",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"symbol"
					],
					"patching_rect": [
						175,
						506,
						110,
						22
					],
					"text": "opendialog folder",
					"varname": "opendlg_ir"
				}
			},
			{
				"box": {
					"id": "pattr_ir_root",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						175,
						532,
						200,
						22
					],
					"text": "pattr ir_root @autorestore 1 @type symbol",
					"varname": "pattr_ir_root"
				}
			},
			{
				"box": {
					"id": "pattr_ir_relpath",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						175,
						558,
						200,
						22
					],
					"text": "pattr ir_relpath @autorestore 1 @type symbol",
					"varname": "pattr_ir_relpath"
				}
			},
			{
				"box": {
					"id": "pre_ir_root",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						420,
						532,
						160,
						22
					],
					"text": "prepend set_ir_root",
					"varname": "pre_ir_root"
				}
			},
			{
				"box": {
					"id": "rcv_set_ir_relpath",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						420,
						532,
						255,
						22
					],
					"text": "receive nam_state_set_ir_relpath",
					"varname": "rcv_set_ir_relpath"
				}
			},
			{
				"box": {
					"id": "pre_set_ir_relpath",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						420,
						558,
						180,
						22
					],
					"text": "prepend set_ir_relpath",
					"varname": "pre_set_ir_relpath"
				}
			},
			{
				"box": {
					"id": "trim_pfx_toggle_ir",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						1846,
						548,
						14,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						746,
						148,
						14,
						14
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Trim Prefix",
							"parameter_shortname": "TrimIR",
							"parameter_type": 1,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								1
							]
						}
					},
					"varname": "trim_pfx_toggle_ir"
				}
			},
			{
				"box": {
					"id": "lbl_trim_ir",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						1863,
						548,
						28,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						763,
						148,
						28,
						14
					],
					"text": "Trim",
					"fontsize": 9,
					"varname": "lbl_trim_ir"
				}
			},
			{
				"box": {
					"id": "pre_trim_ir",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						175,
						584,
						200,
						22
					],
					"text": "prepend set_trim_prefix_ir",
					"varname": "pre_trim_ir"
				}
			},
			{
				"box": {
					"id": "ir_cat_menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						662,
						500,
						276,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						664,
						100,
						276,
						22
					],
					"varname": "ir_cat_menu"
				}
			},
			{
				"box": {
					"id": "ir_file_menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						662,
						526,
						276,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						664,
						122,
						276,
						22
					],
					"varname": "ir_file_menu"
				}
			},
			{
				"box": {
					"id": "pre_sel_ir_cat",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						552,
						200,
						22
					],
					"text": "prepend select_ir_category",
					"varname": "pre_sel_ir_cat"
				}
			},
			{
				"box": {
					"id": "pre_sel_ir",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						578,
						150,
						22
					],
					"text": "prepend select_ir",
					"varname": "pre_sel_ir"
				}
			},
			{
				"box": {
					"id": "btn_ir_cat_prev",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1742,
						500,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						642,
						100,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": "<",
					"texton": "<",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Cat Prev",
							"parameter_shortname": "IRCatPrv",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_ir_cat_prev"
				}
			},
			{
				"box": {
					"id": "pre_btn_ir_cat_prev",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						604,
						160,
						22
					],
					"text": "prepend prev_ir_cat",
					"varname": "pre_btn_ir_cat_prev"
				}
			},
			{
				"box": {
					"id": "btn_ir_cat_next",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						2040,
						500,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						940,
						100,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": ">",
					"texton": ">",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Cat Next",
							"parameter_shortname": "IRCatNxt",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_ir_cat_next"
				}
			},
			{
				"box": {
					"id": "pre_btn_ir_cat_next",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						630,
						160,
						22
					],
					"text": "prepend next_ir_cat",
					"varname": "pre_btn_ir_cat_next"
				}
			},
			{
				"box": {
					"id": "btn_ir_prev",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						1742,
						522,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						642,
						122,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": "<",
					"texton": "<",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Prev",
							"parameter_shortname": "IRPrev",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_ir_prev"
				}
			},
			{
				"box": {
					"id": "pre_btn_ir_prev",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						656,
						160,
						22
					],
					"text": "prepend prev_ir",
					"varname": "pre_btn_ir_prev"
				}
			},
			{
				"box": {
					"id": "btn_ir_next",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"int"
					],
					"patching_rect": [
						2040,
						522,
						22,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						940,
						122,
						22,
						22
					],
					"parameter_enable": 1,
					"mode": 0,
					"text": ">",
					"texton": ">",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Next",
							"parameter_shortname": "IRNext",
							"parameter_type": 2,
							"parameter_enum": [
								"val1",
								"val2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							],
							"parameter_invisible": 1
						}
					},
					"varname": "btn_ir_next"
				}
			},
			{
				"box": {
					"id": "pre_btn_ir_next",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						682,
						160,
						22
					],
					"text": "prepend next_ir",
					"varname": "pre_btn_ir_next"
				}
			},
			{
				"box": {
					"id": "ir_cat_idx",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						940,
						552,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR Cat",
							"parameter_shortname": "IRCat",
							"parameter_type": 2,
							"parameter_enum": [
								"1",
								"2",
								"3",
								"4",
								"5",
								"6",
								"7",
								"8",
								"9",
								"10",
								"11",
								"12",
								"13",
								"14",
								"15",
								"16",
								"17",
								"18",
								"19",
								"20",
								"21",
								"22",
								"23",
								"24",
								"25",
								"26",
								"27",
								"28",
								"29",
								"30",
								"31",
								"32",
								"33",
								"34",
								"35",
								"36",
								"37",
								"38",
								"39",
								"40",
								"41",
								"42",
								"43",
								"44",
								"45",
								"46",
								"47",
								"48",
								"49",
								"50",
								"51",
								"52",
								"53",
								"54",
								"55",
								"56",
								"57",
								"58",
								"59",
								"60",
								"61",
								"62",
								"63",
								"64",
								"65",
								"66",
								"67",
								"68",
								"69",
								"70",
								"71",
								"72",
								"73",
								"74",
								"75",
								"76",
								"77",
								"78",
								"79",
								"80",
								"81",
								"82",
								"83",
								"84",
								"85",
								"86",
								"87",
								"88",
								"89",
								"90",
								"91",
								"92",
								"93",
								"94",
								"95",
								"96",
								"97",
								"98",
								"99",
								"100"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "ir_cat_idx"
				}
			},
			{
				"box": {
					"id": "pre_push_ir_cat_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						940,
						580,
						240,
						22
					],
					"text": "prepend select_ir_cat_by_push",
					"varname": "pre_push_ir_cat_idx"
				}
			},
			{
				"box": {
					"id": "rcv_set_ir_cat_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						552,
						210,
						22
					],
					"text": "receive ir_numbox_set_cat",
					"varname": "rcv_set_ir_cat_idx"
				}
			},
			{
				"box": {
					"id": "pre_set_ir_cat_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						580,
						80,
						22
					],
					"text": "prepend set",
					"varname": "pre_set_ir_cat_idx"
				}
			},
			{
				"box": {
					"id": "ir_file_idx",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						940,
						578,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR File",
							"parameter_shortname": "IRFile",
							"parameter_type": 2,
							"parameter_enum": [
								"1",
								"2",
								"3",
								"4",
								"5",
								"6",
								"7",
								"8",
								"9",
								"10",
								"11",
								"12",
								"13",
								"14",
								"15",
								"16",
								"17",
								"18",
								"19",
								"20",
								"21",
								"22",
								"23",
								"24",
								"25",
								"26",
								"27",
								"28",
								"29",
								"30",
								"31",
								"32",
								"33",
								"34",
								"35",
								"36",
								"37",
								"38",
								"39",
								"40",
								"41",
								"42",
								"43",
								"44",
								"45",
								"46",
								"47",
								"48",
								"49",
								"50",
								"51",
								"52",
								"53",
								"54",
								"55",
								"56",
								"57",
								"58",
								"59",
								"60",
								"61",
								"62",
								"63",
								"64",
								"65",
								"66",
								"67",
								"68",
								"69",
								"70",
								"71",
								"72",
								"73",
								"74",
								"75",
								"76",
								"77",
								"78",
								"79",
								"80",
								"81",
								"82",
								"83",
								"84",
								"85",
								"86",
								"87",
								"88",
								"89",
								"90",
								"91",
								"92",
								"93",
								"94",
								"95",
								"96",
								"97",
								"98",
								"99",
								"100"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "ir_file_idx"
				}
			},
			{
				"box": {
					"id": "pre_push_ir_file_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						940,
						606,
						240,
						22
					],
					"text": "prepend select_ir_file_by_push",
					"varname": "pre_push_ir_file_idx"
				}
			},
			{
				"box": {
					"id": "rcv_set_ir_file_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						578,
						210,
						22
					],
					"text": "receive ir_numbox_set_file",
					"varname": "rcv_set_ir_file_idx"
				}
			},
			{
				"box": {
					"id": "pre_set_ir_file_idx",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1210,
						606,
						80,
						22
					],
					"text": "prepend set",
					"varname": "pre_set_ir_file_idx"
				}
			},
			{
				"box": {
					"id": "ir_live_drop",
					"maxclass": "live.drop",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						1740,
						400,
						320,
						100
					],
					"presentation": 1,
					"presentation_rect": [
						642,
						0,
						320,
						100
					],
					"parameter_enable": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "IR File Drop",
							"parameter_shortname": "IRDrop",
							"parameter_type": 4,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								""
							]
						}
					},
					"varname": "ir_live_drop"
				}
			},
			{
				"box": {
					"id": "pre_drop_ir",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						620,
						710,
						200,
						22
					],
					"text": "prepend load_dropped_ir",
					"varname": "pre_drop_ir"
				}
			},
			{
				"box": {
					"id": "ir_waveform",
					"maxclass": "waveform~",
					"numinlets": 5,
					"numoutlets": 6,
					"outlettype": [
						"float",
						"float",
						"float",
						"float",
						"float",
						"list"
					],
					"patching_rect": [
						1740,
						400,
						320,
						100
					],
					"presentation": 1,
					"presentation_rect": [
						642,
						0,
						320,
						100
					],
					"buffername": "ir_display",
					"allowdrag": 0,
					"ignoreclick": 1,
					"labels": 0,
					"ruler": 0,
					"vticks": 0,
					"varname": "ir_waveform"
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
						"sum_lr",
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
						"sum_lr",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sum_lr",
						0
					],
					"destination": [
						"half",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"half",
						0
					],
					"destination": [
						"in_gain",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"half",
						0
					],
					"destination": [
						"in_gain",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nodestate",
						0
					],
					"destination": [
						"pre_rehydrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_rehydrate",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"thisdev",
						0
					],
					"destination": [
						"delay_startup",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"delay_startup",
						0
					],
					"destination": [
						"msg_getall",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_getall",
						0
					],
					"destination": [
						"nodestate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"thisdev",
						1
					],
					"destination": [
						"pre_sr_changed",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sr_changed",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"in_gain",
						0
					],
					"destination": [
						"nam_ext",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						4
					],
					"destination": [
						"nam_ext",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_ext",
						1
					],
					"destination": [
						"print_nam_meta",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_ext",
						2
					],
					"destination": [
						"msg_nam_loaded",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_nam_loaded",
						0
					],
					"destination": [
						"status_msg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_ext",
						3
					],
					"destination": [
						"pre_nam_error",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_nam_error",
						0
					],
					"destination": [
						"status_msg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						6
					],
					"destination": [
						"status_msg",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"half",
						0
					],
					"destination": [
						"bypass_dry_delay",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"bypass_dry_delay",
						0
					],
					"destination": [
						"bypass_sel",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"bypass_sel",
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
						"bypass_sel",
						0
					],
					"destination": [
						"plugout",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tone_expand_toggle",
						0
					],
					"destination": [
						"collapse_js",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_expand_toggle",
						0
					],
					"destination": [
						"collapse_js",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"collapse_js",
						0
					],
					"destination": [
						"collapse_tp",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"collapse_js",
						1
					],
					"destination": [
						"thisdev",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"bypass_toggle",
						0
					],
					"destination": [
						"bypass_plus1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"bypass_plus1",
						0
					],
					"destination": [
						"bypass_sel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_nam_root",
						0
					],
					"destination": [
						"opendlg_nam",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"opendlg_nam",
						0
					],
					"destination": [
						"pattr_nam_root",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"opendlg_nam",
						0
					],
					"destination": [
						"pre_nam_root",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_nam_root",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_nam_root",
						0
					],
					"destination": [
						"nodestate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rcv_set_nam_relpath",
						0
					],
					"destination": [
						"pre_set_nam_relpath",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_nam_relpath",
						0
					],
					"destination": [
						"nodestate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"trim_pfx_toggle_nam",
						0
					],
					"destination": [
						"pre_trim_nam",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_trim_nam",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						0
					],
					"destination": [
						"nam_cat_menu",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						1
					],
					"destination": [
						"nam_model_menu",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_cat_menu",
						0
					],
					"destination": [
						"pre_sel_nam_cat",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sel_nam_cat",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_model_menu",
						0
					],
					"destination": [
						"pre_sel_nam_model",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sel_nam_model",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_cat_prev",
						0
					],
					"destination": [
						"pre_btn_cat_prev",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_cat_prev",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_cat_next",
						0
					],
					"destination": [
						"pre_btn_cat_next",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_cat_next",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_model_prev",
						0
					],
					"destination": [
						"pre_btn_model_prev",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_model_prev",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_model_next",
						0
					],
					"destination": [
						"pre_btn_model_next",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_model_next",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_cat_idx",
						0
					],
					"destination": [
						"pre_push_nam_cat_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_nam_cat_idx",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rcv_set_nam_cat_idx",
						0
					],
					"destination": [
						"pre_set_nam_cat_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_nam_cat_idx",
						0
					],
					"destination": [
						"nam_cat_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_model_idx",
						0
					],
					"destination": [
						"pre_push_nam_model_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_nam_model_idx",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rcv_set_nam_model_idx",
						0
					],
					"destination": [
						"pre_set_nam_model_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_nam_model_idx",
						0
					],
					"destination": [
						"nam_model_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_live_drop",
						0
					],
					"destination": [
						"pre_drop_nam",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_drop_nam",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"in_gain",
						0
					],
					"destination": [
						"ng_trigger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_ext",
						0
					],
					"destination": [
						"ng_gain",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ng_trigger",
						1
					],
					"destination": [
						"ng_gain",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_ext",
						0
					],
					"destination": [
						"gate_sel",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ng_gain",
						0
					],
					"destination": [
						"gate_sel",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"gate_thresh_dial",
						0
					],
					"destination": [
						"pre_gate_thresh",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_gate_thresh",
						0
					],
					"destination": [
						"ng_trigger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"gate_on_toggle",
						0
					],
					"destination": [
						"gate_on_plus1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"gate_on_plus1",
						0
					],
					"destination": [
						"gate_sel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"in_gain",
						0
					],
					"destination": [
						"nam_dry_mul",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"gate_sel",
						0
					],
					"destination": [
						"nam_wet_mul",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_blend_dial",
						0
					],
					"destination": [
						"nam_blend_div",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_blend_div",
						0
					],
					"destination": [
						"nam_blend_inv",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_blend_div",
						0
					],
					"destination": [
						"nam_wet_mul",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_blend_inv",
						0
					],
					"destination": [
						"nam_dry_mul",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_dry_mul",
						0
					],
					"destination": [
						"nam_blend_sum",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_wet_mul",
						0
					],
					"destination": [
						"nam_blend_sum",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_blend_sum",
						0
					],
					"destination": [
						"out_gain",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"nam_blend_sum",
						0
					],
					"destination": [
						"out_gain",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"out_gain",
						0
					],
					"destination": [
						"tone_ext",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tone_ext",
						1
					],
					"destination": [
						"eq_curve_jsui",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"out_gain",
						0
					],
					"destination": [
						"tone_sel",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tone_ext",
						0
					],
					"destination": [
						"tone_sel",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"bass_dial",
						0
					],
					"destination": [
						"pre_bass",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_bass",
						0
					],
					"destination": [
						"tone_ext",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"mid_dial",
						0
					],
					"destination": [
						"pre_mid",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_mid",
						0
					],
					"destination": [
						"tone_ext",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"treble_dial",
						0
					],
					"destination": [
						"pre_treble",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_treble",
						0
					],
					"destination": [
						"tone_ext",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tone_on_toggle",
						0
					],
					"destination": [
						"tonestack_on_plus1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tonestack_on_plus1",
						0
					],
					"destination": [
						"tone_sel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						5
					],
					"destination": [
						"ir_buf",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_buf",
						1
					],
					"destination": [
						"msg_irdisplay_process",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_irdisplay_process",
						0
					],
					"destination": [
						"irdisplay_obj",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"irdisplay_obj",
						0
					],
					"destination": [
						"msg_set_waveform_display",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_set_waveform_display",
						0
					],
					"destination": [
						"ir_waveform",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"lb_irconv",
						0
					],
					"destination": [
						"msg_set_ir",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_buf",
						1
					],
					"destination": [
						"msg_set_ir",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_set_ir",
						0
					],
					"destination": [
						"mconv",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tone_sel",
						0
					],
					"destination": [
						"mconv",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tone_sel",
						0
					],
					"destination": [
						"ir_blend_dry_delay",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_dry_delay",
						0
					],
					"destination": [
						"ir_dry_mul",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"mconv",
						0
					],
					"destination": [
						"ir_norm",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						7
					],
					"destination": [
						"ir_norm",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_norm",
						0
					],
					"destination": [
						"ir_wet_mul",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_dial",
						0
					],
					"destination": [
						"ir_blend_div",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_div",
						0
					],
					"destination": [
						"ir_blend_inv",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_div",
						0
					],
					"destination": [
						"ir_wet_mul",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_inv",
						0
					],
					"destination": [
						"ir_dry_mul",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_dry_mul",
						0
					],
					"destination": [
						"ir_blend_sum",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_wet_mul",
						0
					],
					"destination": [
						"ir_blend_sum",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_dry_delay",
						0
					],
					"destination": [
						"ir_sel",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_blend_sum",
						0
					],
					"destination": [
						"ir_sel",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_on_toggle",
						0
					],
					"destination": [
						"ir_on_plus1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_on_plus1",
						0
					],
					"destination": [
						"ir_sel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_sel",
						0
					],
					"destination": [
						"bypass_sel",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"mconv",
						1
					],
					"destination": [
						"route_latency",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"route_latency",
						0
					],
					"destination": [
						"unpack_lat",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"unpack_lat",
						0
					],
					"destination": [
						"lat_trig",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"lat_trig",
						0
					],
					"destination": [
						"ir_blend_dry_delay",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"lat_trig",
						1
					],
					"destination": [
						"msg_latency",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_latency",
						0
					],
					"destination": [
						"lat_defer",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"lat_defer",
						0
					],
					"destination": [
						"thisdev",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"lat_trig",
						2
					],
					"destination": [
						"bypass_dry_delay",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						5
					],
					"destination": [
						"route_read_sfinfo",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"route_read_sfinfo",
						0
					],
					"destination": [
						"pre_open_sfinfo",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_open_sfinfo",
						0
					],
					"destination": [
						"sfinfo_dur",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sfinfo_dur",
						3
					],
					"destination": [
						"div_ms",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"div_ms",
						0
					],
					"destination": [
						"sprintf_dur",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"sprintf_dur",
						0
					],
					"destination": [
						"pre_set_dur",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_dur",
						0
					],
					"destination": [
						"dur_display",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_ir_root",
						0
					],
					"destination": [
						"opendlg_ir",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"opendlg_ir",
						0
					],
					"destination": [
						"pattr_ir_root",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"opendlg_ir",
						0
					],
					"destination": [
						"pre_ir_root",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_ir_root",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_ir_root",
						0
					],
					"destination": [
						"nodestate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rcv_set_ir_relpath",
						0
					],
					"destination": [
						"pre_set_ir_relpath",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_ir_relpath",
						0
					],
					"destination": [
						"nodestate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"trim_pfx_toggle_ir",
						0
					],
					"destination": [
						"pre_trim_ir",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_trim_ir",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						2
					],
					"destination": [
						"ir_cat_menu",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"jsloader",
						3
					],
					"destination": [
						"ir_file_menu",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_cat_menu",
						0
					],
					"destination": [
						"pre_sel_ir_cat",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sel_ir_cat",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_file_menu",
						0
					],
					"destination": [
						"pre_sel_ir",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sel_ir",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_ir_cat_prev",
						0
					],
					"destination": [
						"pre_btn_ir_cat_prev",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_ir_cat_prev",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_ir_cat_next",
						0
					],
					"destination": [
						"pre_btn_ir_cat_next",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_ir_cat_next",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_ir_prev",
						0
					],
					"destination": [
						"pre_btn_ir_prev",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_ir_prev",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn_ir_next",
						0
					],
					"destination": [
						"pre_btn_ir_next",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_btn_ir_next",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_cat_idx",
						0
					],
					"destination": [
						"pre_push_ir_cat_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_ir_cat_idx",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rcv_set_ir_cat_idx",
						0
					],
					"destination": [
						"pre_set_ir_cat_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_ir_cat_idx",
						0
					],
					"destination": [
						"ir_cat_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_file_idx",
						0
					],
					"destination": [
						"pre_push_ir_file_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_ir_file_idx",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"rcv_set_ir_file_idx",
						0
					],
					"destination": [
						"pre_set_ir_file_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_set_ir_file_idx",
						0
					],
					"destination": [
						"ir_file_idx",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"ir_live_drop",
						0
					],
					"destination": [
						"pre_drop_ir",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_drop_ir",
						0
					],
					"destination": [
						"jsloader",
						0
					]
				}
			}
		],
		"dependency_cache": [],
		"autosave": 0
	}
}