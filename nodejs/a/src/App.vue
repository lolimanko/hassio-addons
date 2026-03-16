<script setup>

//import VueDatePicker from '@vuepic/vue-datepicker';
//import '@vuepic/vue-datepicker/dist/main.css'

//import {Pane} from 'tweakpane/dist/tweakpane.min.js';
//import {Pane} from 'tweakpane'


import { ref, onMounted  } from 'vue';
import axios from 'axios';

const number = ref();
const numbers = ref();

const log = ref();
//const phppath = 'http://localhost/getstaff.php';
const phppath = 'https://buvi.duckdns.org:13517/pgapi_supervise.php';
const ofheight = ref();


const state = {
  fps: 30,
  color: "#0f0",
  charset: "01",
  size: 25
};
/*
const gui = new Pane({
  title: "1337 Matrix by pavi2410"
});
const fpsCtrl = gui.addBinding(state, "fps", { min: 1, max: 120, step: 1 });
gui.addBinding(state, "color");
gui.addBinding(state, "charset");
const sizeCtrl = gui.addBinding(state, "size", { min: 1, max: 120, step: 1 });
*/

const canvas = ref()


//let ctx;

onMounted(() => {
//alert(document.body.offsetHeight );818
//alert(document.body.scrollHeight  );818
//alert(window.screen.height   );904
//alert(innerHeight    );

	ofheight.value = document.body.scrollHeight ;
	const random = (items) => items[Math.floor(Math.random() * items.length)];
	let w, h, p;
	const ctx = canvas.value.getContext('2d')

	w = canvas.value.width = innerWidth;
	h = canvas.value.height = document.body.scrollHeight;
	p = Array(Math.ceil(w / state.size)).fill(0);
  
	const draw = () => {
		ctx.fillStyle = "rgba(0,0,0,.05)";
		ctx.fillRect(0, 0, w, h);
		ctx.fillStyle = state.color;

		ctx.font = state.size + "px monospace";
		for (let i = 0; i < p.length; i++) {
			let v = p[i];
			ctx.fillText(random(state.charset), i * state.size, v);
			p[i] = v >= h || v >= 10000 * Math.random() ? 0 : v + state.size;
		}
	};
	let interval = setInterval(draw, 1000 / state.fps);
  



	axios.get(phppath)
		.then(function(response) {
			
			if(response.data){
			
				if(response.data.numbers){

					numbers.value = response.data.numbers
				}else{
					numbers.value = ''
				}
				if(response.data.log){
				//response.data.log.replaceAll("}","");
					//log.value = response.data.log.split(',')
					log.value = response.data.log
				}else{
					log.value = ''
				}
			}
		})
		.catch(function (error) {console.log(error);});


});


function add_number(event) {
	if(numbers.value.indexOf(number.value)!=-1){
		alert("請勿重複輸入同一員工編號");
		return;
	}
	axios.post(phppath,{

		number: number.value
	})
	.then(function(response) {

		numbers.value.push(number.value);
	})
	.catch(function (error) {console.log(error);});

}
function delete_number(li_number) {
	//alert(number.value);
	axios.delete(phppath+"?number="+li_number,{

		//number: number.value
	})
	.then(function(response) {

		numbers.value.splice (numbers.value.indexOf(li_number), 1);
	})
	.catch(function (error) {console.log(error);});

}
</script>

<template>
   <canvas id="canvas" ref="canvas" ></canvas>
	
	<div id="ofclass" :style="{ 'height': ofheight + 'px' }">
	<div class="formclass">	
	
		<h1>督導自動出勤打卡</h1>
		<h2>已啟用員工編號一覽:</h2>
		<div class="numbers">
			<li v-for="item in numbers">
				<a >{{ item }} - </a>
				<b-button @click="delete_number( item )">刪除</b-button>
			</li>

		</div>
		<br />
		<h2>員工編號:</h2>
		<div class="inputandbutton" >
				

			<input v-model="number">
			<b-button @click="add_number()">新增</b-button>
		
		</div>
		<br />
		<h3>08:00上班打卡，17:30下班打卡，假日不打卡，假日判斷資料來源為<a href="https://api.pin-yi.me/taiwan-calendar/swagger/index.html">台灣行事曆 API</a></h3>
		<div class="logclass">

			<li v-for="item in log">
				<a :href="`supervise/${item}.png`">{{ item }} 已自動打卡</a>
			</li>
		</div>
		
	</div>
	</div>
	

  

</template>

<style>
@import url(https://fonts.googleapis.com/earlyaccess/cwtexyen.css);
body::-webkit-scrollbar {
    display: none;
}
#app{
    padding: 0;


	margin:0;
}
#ofclass{
	display: block;
	width :100%;
	overflow-y:auto;
	position: absolute;
	top: 0;
	right: 0;
	left: 0;
	padding: 0;
	margin:0;
}
canvas{
position: relative;
	padding: 0;
	margin:0;
	top: 0;
	left: 0;
}
a{
	color: #9999FF;
	font-family: 'cwTeXYen', sans-serif;
}
h1{
	color: #FFFFFF;
	background-color: rgba(0, 0, 0, 0.6) ;
	font-family: 'cwTeXYen', sans-serif;
	font-size:2.6em;
	text-align:center;
	font-weight: 600;

}
h2{
	color: #FFFFFF;
	background-color: rgba(0, 0, 0, 0.6) ;
	font-family: 'cwTeXYen', sans-serif;
	text-align:center;
	font-size:2em;
	font-weight: 600;
}
h3{
	color: #FFFFFF;
	background-color: rgba(0, 0, 0, 0.6) ;
	font-family: 'cwTeXYen', sans-serif;
	text-align:center;
	font-weight: 600;
}
.formclass{

	display: flex;
  flex-direction: column;
  justify-content: center;    
  align-content: center;      
	align-items: center;


}
.dp__theme_dark {
	--dp-background-color:rgba(0, 0, 0, 0.8);
}
:root {
	--dp-font-size: 1.7rem; 
	--dp-cell-size: 50px;
	--dp-menu-min-width: 350px;
}
.dp__main{


}
.numbers{

	color: #FFFFFF;
	background-color: rgba(0, 0, 0, 0.6) ;
	text-align:center;
	font-size:1.5em;
	padding: 0rem 0rem;
	margin: 0rem ;
}

.logclass{

	color: #FFFFFF;
	background-color: rgba(0, 0, 0, 0.6) ;
	text-align:center;
	font-size:1.2em;
	padding: 0rem 0rem;
	margin: 0rem ;
}

</style>
