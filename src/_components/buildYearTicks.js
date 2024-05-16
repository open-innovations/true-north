export default function ({ field, data, step }){
	let s = parseInt(data.rows[0][field].substr(0,4));
	let e = parseInt(data.rows[data.rows.length-1][field].substr(0,4));
	if(typeof step!=="number") step = 1;
	s = Math.ceil(s/step)*step;
	e = Math.floor(e/step)*step;
	let ticks = [];
	for(let y = s; y <= e; y += step){
		ticks.push({'value':(new Date(y+'-01-01')).getTime()/1000,'grid':true,'label':""+y});
	}
	return ticks;
}