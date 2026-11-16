# Made by tooling/video_gen/finish.py (encode): each picture's videos, in the order they were picked
# on the /plan page. "loop" plays seamlessly over and over, after its "intro" if it has one (the frames
# from the still into the loop); otherwise the video plays once. Read by src/vn/Background.gd.
const VIDEOS = {
	"res://data/background_lists/ashely_poker2/FINAL__NAKED/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/FINAL__NAKED/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/FINAL__NAKED/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/LOSE_P1_ASS_KISS__DRESSED/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/LOSE_P1_ASS_KISS__DRESSED/02.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/LOSE_P1_ASS_KISS__DRESSED/02_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/LOSE_P1_ASS_KISS__DRESSED/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/LOSE_P1_ASS_KISS__DRESSED/04.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/LOSE_P1_ASS_KISS__DRESSED/04_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/LOSE_P1_ASS_KISS__SHORTS_OFF/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/LOSE_P1_ASS_KISS__SHORTS_OFF/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/LOSE_P1_ASS_KISS__SHORTS_OFF/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L1_TRUTH__PANTIES/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__PANTIES/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__PANTIES/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L1_TRUTH__TOP_OFF/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L1_TRUTH__TOP_OFF/03.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/03.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/03_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L1_TRUTH__TOP_OFF/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/03.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/03_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L1_TRUTH__TOP_OFF/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L2_NICE__TOP_OFF/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L2_NICE__TOP_OFF/01.ogv", "loop": true},
	],
	"res://data/background_lists/ashely_poker2/WIN_L2_NICE__TOP_OFF/03.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L2_NICE__TOP_OFF/03.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L2_NICE__TOP_OFF/03_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L3_SMILE/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L3_SMILE/05.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L3_SMILE/06.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L3_SMILE/06.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L3_SMILE/08.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L3_SMILE/08.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/04.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/06.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/06.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/07.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/07.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/07_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/09.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/09.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/09_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/11.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/11.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/11_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/12.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/12_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/12_2_intro.ogv"},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/12_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/12_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/18.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/18_1.ogv", "loop": true},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/18_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/18_2_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/20.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/20.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/20_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/21.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/21_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/21_2_intro.ogv"},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/21_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/21_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/22.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/22_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/22_2_intro.ogv"},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/22_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/22_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/23.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/23.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/23_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/24.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/24.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/24_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/26.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/26.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/26_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/31.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/31.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/31_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/32.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/32_2.ogv", "loop": true},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/33.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/33.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/35.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/35.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/35_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/36.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/36_2.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/36_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/36_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/37.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/37_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/37_2_intro.ogv"},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/37_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/37_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/41.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/41.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/41_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/47.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/47.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/47_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/48.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/48.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/49.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/49.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/49_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/51.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/51.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/51_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/53.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/53.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/53_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/55.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/55.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/55_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/57.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/57.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/58.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/32_3.ogv", "loop": true},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/59.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/32_4.ogv", "loop": true},
	],
	"res://data/background_lists/ashely_poker2/WIN_L4_KISS/60.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L4_KISS/32_6.ogv", "loop": true},
	],
	"res://data/background_lists/ashely_poker2/WIN_MR1_FINGER/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_MR1_FINGER/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_MR1_FINGER/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_MR1_FINGER/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_MR1_FINGER/02.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_MR1_FINGER/02_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_MR1_KISS/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_L1_TRUTH__TOP_OFF/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_MR3_INSPECT/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_MR3_INSPECT/02.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_S1_TOP/03.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/03_2.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/03_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/03_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_S1_TOP/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/04.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/04_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_S1_TOP/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_S2_WALK/07.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S2_WALK/07.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_S3_SHORTS/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S3_SHORTS/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S3_SHORTS/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_S4_PANTIES/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/04.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/04_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_S4_PANTIES/12.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/12.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_S4_PANTIES/20.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/20.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/20_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_S4_PANTIES/21.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/20.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_S4_PANTIES/20_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__DRESSED/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/02.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__DRESSED/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/04.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__DRESSED/08.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/08.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/08_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__DRESSED/10.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/10.ogv", "loop": true},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__DRESSED/11.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/11.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__DRESSED/11_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__PANTIES/03.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__PANTIES/03.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__PANTIES/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__PANTIES/04_cycle.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__PANTIES/04_1_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__TOP_OFF/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__TOP_OFF/02.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__TOP_OFF/02_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__TOP_OFF/09.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__TOP_OFF/09.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_X1_BUTT__TOP_OFF/10.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__TOP_OFF/10.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X1_BUTT__TOP_OFF/10_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__DRESSED/06.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__DRESSED/06.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__DRESSED/06_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__DRESSED/09.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__DRESSED/09.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__DRESSED/09_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/02.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/02_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/03.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/03.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/03_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/04.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/04_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/08.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/08_1.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/08_1_intro.ogv"},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/08_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/08_2_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/09.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/09.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/09_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/11.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/11.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/11_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X2_BREAST__TOP_OFF/12.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/12.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X2_BREAST__TOP_OFF/12_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__DRESSED/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/02_1.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/02_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/02_2_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__DRESSED/03.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/02_1.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/02_2.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/02_2_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__DRESSED/08.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/08.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/08_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__DRESSED/09.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/09.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/09_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__DRESSED/11.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/11.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/11_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__DRESSED/12.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/12.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__DRESSED/12_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__TOP_OFF/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__TOP_OFF/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/02.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/02_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__TOP_OFF/04.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/04.ogv", "loop": false},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_BJ__TOP_OFF/05.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/05.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_BJ__TOP_OFF/05_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_UNDER__DRESSED/01.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__DRESSED/01.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__DRESSED/01_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X3_UNDER__TOP_OFF/07.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__TOP_OFF/07_1.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__TOP_OFF/07_2.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__TOP_OFF/07_3.ogv", "loop": false},
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__TOP_OFF/07_4.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X3_UNDER__TOP_OFF/07_4_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X4_SEX__DRESSED/02.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X4_SEX__DRESSED/02.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X4_SEX__DRESSED/02_intro.ogv"},
	],
	"res://data/background_lists/ashely_poker2/WIN_X4_SEX__DRESSED/08.webp": [
		{"video": "res://data/background_lists/ashely_poker2/video/WIN_X4_SEX__DRESSED/08.ogv", "loop": true, "intro": "res://data/background_lists/ashely_poker2/video/WIN_X4_SEX__DRESSED/08_intro.ogv"},
	],
}
