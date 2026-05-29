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
			1000.0,
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
						10,
						10,
						110,
						22
					],
					"text": "live.thisdevice",
					"varname": "thisdev"
				}
			},
			{
				"box": {
					"id": "delay_init",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10,
						36,
						80,
						22
					],
					"text": "delay 10",
					"varname": "delay_init"
				}
			},
			{
				"box": {
					"id": "msg_init",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10,
						62,
						60,
						22
					],
					"text": "init",
					"varname": "msg_init"
				}
			},
			{
				"box": {
					"id": "jsloader",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"patching_rect": [
						100,
						10,
						190,
						22
					],
					"text": "js nam_test_loader.js",
					"varname": "jsloader"
				}
			},
			{
				"box": {
					"id": "cat_menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						600,
						300,
						320,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						320,
						22
					],
					"varname": "cat_menu"
				}
			},
			{
				"box": {
					"id": "pre_sel_cat",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10,
						88,
						200,
						22
					],
					"text": "prepend select_category",
					"varname": "pre_sel_cat"
				}
			},
			{
				"box": {
					"id": "model_menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"patching_rect": [
						600,
						324,
						320,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						24,
						320,
						22
					],
					"varname": "model_menu"
				}
			},
			{
				"box": {
					"id": "pre_sel_model",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						10,
						114,
						200,
						22
					],
					"text": "prepend select_model",
					"varname": "pre_sel_model"
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
						600,
						348,
						320,
						14
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						48,
						320,
						14
					],
					"text": "(loading...)",
					"fontsize": 9,
					"varname": "status_msg"
				}
			},
			{
				"box": {
					"id": "live_banks",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						10,
						100,
						22
					],
					"text": "live.banks",
					"varname": "live_banks"
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
						800,
						60,
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
								"1960 Fender Tweed Deluxe 5E3",
								"1970s Sunn Concert Lead + 2x15 Cab",
								"API 512c",
								"Avalon AD2022 Preamp",
								"Dumble Steel String Singer",
								"Fender Deluxe Reverb '65 Reissue _ Clean _ SM57 + Royer R-121 + Room",
								"Fender Deluxe Reverb II - clean and overdrive",
								"Fender Super Reverb 1977",
								"J. Rockett _The Jeff_ Archer",
								"Loose files",
								"Neve 31102 Stereo Pair Console Pre & EQ",
								"Peavey 240 Standard + 2x15 Sunn Cab",
								"Roland JC 120B Jazz Chorus",
								"Silvertone Model 1484 Twin Twelve - Vintage Mid 60s"
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
					"id": "pre_push_cat",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						86,
						230,
						22
					],
					"text": "prepend select_cat_by_push",
					"varname": "pre_push_cat"
				}
			},
			{
				"box": {
					"id": "Model0",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						110,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 0",
							"parameter_shortname": "Model0",
							"parameter_type": 2,
							"parameter_enum": [
								"M160 MIDDLE - T 4, I 2, M 5",
								"M160 MIDDLE - T 5, I 3, M 9",
								"M160 MIDDLE - T 6, I 11, M 12",
								"MD 421 CAP_CENTER - T 6, I 11, M 12",
								"MD 421 EDGE - T 6, I 11, M 12",
								"MD 421 MIDDLE - T 6, I 11, M 12",
								"MD 421 OFF AXIS + 45 DEGREES - T 6, I 11, M 12",
								"SM57 CAP EDGE - T 4, I 2, M 5",
								"SM57 CAP EDGE - T 5, I 3, M 9",
								"SM57 CAP EDGE - T 6, I 11, M 12"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model0"
				}
			},
			{
				"box": {
					"id": "pre_push_Model0",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						136,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model0"
				}
			},
			{
				"box": {
					"id": "Model1",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						136,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 1",
							"parameter_shortname": "Model1",
							"parameter_type": 2,
							"parameter_enum": [
								"Electro-Voice 635a - Middle, Normal + Treble Boost - Bass 6, Mid 5, Treble 5",
								"Electro-Voice 635a Middle, Normal - Bass 6, Mid 5, Treble 5",
								"M160 Middle, Normal + Treble Boost - Bass 6, Mid 5, Treble 5",
								"M160 Middle, Normal - Bass 6, Mid 5, Treble 5",
								"MD 421 Middle, Normal  - Bass 6, Mid 5, Treble 5",
								"MD 421 Middle, Normal + Treble Boost - Bass 6, Mid 5, Treble 5",
								"SM57 Middle, Normal + Treble Boost - Bass 6, Mid 5, Treble 5",
								"Shure SM57 Middle, Normal - Bass 6, Mid 5, Treble 5"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model1"
				}
			},
			{
				"box": {
					"id": "pre_push_Model1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						162,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model1"
				}
			},
			{
				"box": {
					"id": "Model2",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						162,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 2",
							"parameter_shortname": "Model2",
							"parameter_type": 2,
							"parameter_enum": [
								"left mic gain 3",
								"left mic gain 5",
								"left mic gain 8",
								"right mic gain 3",
								"right mic gain 5",
								"right mic gain 8"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model2"
				}
			},
			{
				"box": {
					"id": "pre_push_Model2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						188,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model2"
				}
			},
			{
				"box": {
					"id": "Model3",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						188,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 3",
							"parameter_shortname": "Model3",
							"parameter_type": 2,
							"parameter_enum": [
								"22 dB - Chan 1",
								"22 dB - Chan 2",
								"30 dB - Chan 1",
								"30 dB - Chan 2",
								"38 dB - Chan 1",
								"38 dB - Chan 2",
								"46 dB - Chan 1",
								"46 dB - Chan 2",
								"54 dB - Chan 1",
								"54 dB - Chan 2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model3"
				}
			},
			{
				"box": {
					"id": "pre_push_Model3",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						214,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model3"
				}
			},
			{
				"box": {
					"id": "Model4",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						214,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 4",
							"parameter_shortname": "Model4",
							"parameter_type": 2,
							"parameter_enum": [
								"Clean",
								"Drive 1",
								"Drive 2"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model4"
				}
			},
			{
				"box": {
					"id": "pre_push_Model4",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						240,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model4"
				}
			},
			{
				"box": {
					"id": "Model5",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						240,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 5",
							"parameter_shortname": "Model5",
							"parameter_type": 2,
							"parameter_enum": [
								"Fender DRRI _ Clean _ Room Only _ Full Rig",
								"Fender DRRI _ Clean _ SM57 + Royer R-121 (No Room) _ Full Rig",
								"Fender DRRI _ Clean _ SM57 + Royer R-121 + Room _ Full Rig",
								"NEW VERSION _ Fender DRRI _ Clean _ Room Only _ Full Rig",
								"NEW VERSION _ Fender DRRI _ Clean _ SM57 + Royer R-121 (No Room) _ Full Rig",
								"NEW VERSION _ Fender DRRI _ Clean _ SM57 + Royer R-121 + Room _ Full Rig"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model5"
				}
			},
			{
				"box": {
					"id": "pre_push_Model5",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						266,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model5"
				}
			},
			{
				"box": {
					"id": "Model6",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						266,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 6",
							"parameter_shortname": "Model6",
							"parameter_type": 2,
							"parameter_enum": [
								"DRII_v3_t1_b3_p5_PR30",
								"DRII_v3_t1_b3_p5_SM57",
								"DRII_v3_t3_b3_p5_PR-30",
								"DRII_v3_t3_b3_p5_SM57",
								"DRII_v3pB_t3_b3_p5_PR30",
								"DRII_v3pb_t3_b3_p5_SM57",
								"DRIIcrnch_v5_g5_Mv3_t4_m7p_b3_p5_PR30",
								"DRIIcrnch_v5_g5_Mv3_t4_m7p_b3_p7_SM57",
								"DRIIcrnch_v5_g7_Mv3_t4_m7_b3_p5_PR30",
								"DRIIcruch_v5_g7_Mv3_t4_m7_b3_p5_SM57",
								"DRIIoverdSM57_v4_g5_Mv3_t4_m5p_b3_p5",
								"Deluxe Reverb II_two overdrives into clean channel with SM57"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model6"
				}
			},
			{
				"box": {
					"id": "pre_push_Model6",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						292,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model6"
				}
			},
			{
				"box": {
					"id": "Model7",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						292,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 7",
							"parameter_shortname": "Model7",
							"parameter_type": 2,
							"parameter_enum": [
								"AKG 414",
								"sm57 and AKG 414",
								"sm57"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model7"
				}
			},
			{
				"box": {
					"id": "pre_push_Model7",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						318,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model7"
				}
			},
			{
				"box": {
					"id": "Model8",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						318,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 8",
							"parameter_shortname": "Model8",
							"parameter_type": 2,
							"parameter_enum": [
								"Clean Boost",
								"Gain 10 - Treble Boost",
								"Gain 10",
								"Gain 2.5",
								"Gain 5",
								"Gain 7.5 - Treble Boost",
								"Gain 7.5"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model8"
				}
			},
			{
				"box": {
					"id": "pre_push_Model8",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						344,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model8"
				}
			},
			{
				"box": {
					"id": "Model9",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						344,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 9",
							"parameter_shortname": "Model9",
							"parameter_type": 2,
							"parameter_enum": [
								"1964 VOX AC50 Mk. I (Potentially ex-beatles)",
								"Acoustic Sim",
								"Neve + 1176 + 1176",
								"Sovtek Green Russian Big Muff Clone",
								"Sunn Lucky Number 7 Capture"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model9"
				}
			},
			{
				"box": {
					"id": "pre_push_Model9",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						370,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model9"
				}
			},
			{
				"box": {
					"id": "Model10",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						370,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 10",
							"parameter_shortname": "Model10",
							"parameter_type": 2,
							"parameter_enum": [
								"30 - L",
								"30 - R",
								"40 - L",
								"40 - R",
								"50 - L",
								"50 - R",
								"60 - L",
								"60 - R",
								"70 - L",
								"70 - R"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model10"
				}
			},
			{
				"box": {
					"id": "pre_push_Model10",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						396,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model10"
				}
			},
			{
				"box": {
					"id": "Model11",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						396,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 11",
							"parameter_shortname": "Model11",
							"parameter_type": 2,
							"parameter_enum": [
								"M160 - MIDDLE - BRIGHT_HI",
								"M160 - MIDDLE - JUMPED",
								"MD 421 - CAP EDGE - BRIGHT_HI",
								"MD 421 - CAP EDGE - JUMPED",
								"MD 421 - CENTER - JUMPED",
								"MD 421 - EDGE - JUMPED",
								"MD 421 - MIDDLE - JUMPED",
								"MD 421 - OFF AXIS + 45 DEGREES - JUMPED",
								"SM57 - CAP EDGE - BRIGHT_HI",
								"SM57 - CAP EDGE - JUMPED"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model11"
				}
			},
			{
				"box": {
					"id": "pre_push_Model11",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						422,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model11"
				}
			},
			{
				"box": {
					"id": "Model12",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						422,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 12",
							"parameter_shortname": "Model12",
							"parameter_type": 2,
							"parameter_enum": [
								"Off - SM57 & Royer 101",
								"Off, Royer 101",
								"Off, SM57",
								"On, Royer R-101 & SM57",
								"On, Royer R-101",
								"On, SM57"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model12"
				}
			},
			{
				"box": {
					"id": "pre_push_Model12",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						448,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model12"
				}
			},
			{
				"box": {
					"id": "Model13",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"int",
						"bang"
					],
					"patching_rect": [
						800,
						448,
						60,
						22
					],
					"parameter_enable": 1,
					"hidden": 1,
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "NAM Model 13",
							"parameter_shortname": "Model13",
							"parameter_type": 2,
							"parameter_enum": [
								"V10 - Mic Sum",
								"V10 - R121",
								"V10 - SM57",
								"V4 - Mic Sum",
								"V4 - R121",
								"V4 - SM57",
								"V6 - Mic Sum",
								"V6 - R121",
								"V6 - SM57"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					},
					"varname": "Model13"
				}
			},
			{
				"box": {
					"id": "pre_push_Model13",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						800,
						474,
						250,
						22
					],
					"text": "prepend select_model_by_push",
					"varname": "pre_push_Model13"
				}
			},
			{
				"box": {
					"id": "btn_diag",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						600,
						372,
						200,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						72,
						200,
						22
					],
					"text": "diag_params",
					"varname": "btn_diag"
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"thisdev",
						0
					],
					"destination": [
						"delay_init",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"delay_init",
						0
					],
					"destination": [
						"msg_init",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg_init",
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
						"cat_menu",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"cat_menu",
						0
					],
					"destination": [
						"pre_sel_cat",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sel_cat",
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
						1
					],
					"destination": [
						"model_menu",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"model_menu",
						0
					],
					"destination": [
						"pre_sel_model",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_sel_model",
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
						"status_msg",
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
						"pre_push_cat",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_cat",
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
						"Model0",
						0
					],
					"destination": [
						"pre_push_Model0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model0",
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
						"Model1",
						0
					],
					"destination": [
						"pre_push_Model1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model1",
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
						"Model2",
						0
					],
					"destination": [
						"pre_push_Model2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model2",
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
						"Model3",
						0
					],
					"destination": [
						"pre_push_Model3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model3",
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
						"Model4",
						0
					],
					"destination": [
						"pre_push_Model4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model4",
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
						"Model5",
						0
					],
					"destination": [
						"pre_push_Model5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model5",
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
						"Model6",
						0
					],
					"destination": [
						"pre_push_Model6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model6",
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
						"Model7",
						0
					],
					"destination": [
						"pre_push_Model7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model7",
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
						"Model8",
						0
					],
					"destination": [
						"pre_push_Model8",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model8",
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
						"Model9",
						0
					],
					"destination": [
						"pre_push_Model9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model9",
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
						"Model10",
						0
					],
					"destination": [
						"pre_push_Model10",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model10",
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
						"Model11",
						0
					],
					"destination": [
						"pre_push_Model11",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model11",
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
						"Model12",
						0
					],
					"destination": [
						"pre_push_Model12",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model12",
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
						"Model13",
						0
					],
					"destination": [
						"pre_push_Model13",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"pre_push_Model13",
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
						"btn_diag",
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