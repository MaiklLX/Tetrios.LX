/* TETRIOS.LX — self-playing decorative arena. Independent from the real game. */
(() => {
 const canvas=document.querySelector('#menu .hero-arena-canvas'),host=canvas?.parentElement;
 if(!canvas||!host)return;
 const ctx=canvas.getContext('2d',{alpha:true});if(!ctx)return;
 const reduce=matchMedia('(prefers-reduced-motion: reduce)');
 const colors=['#36dfff','#9d75ff','#ffbd55','#63f5bd','#ff6f9f','#6e9cff','#d7f36b'];
 const shapes=[[[0,1],[1,1],[2,1],[3,1]],[[0,0],[1,0],[0,1],[1,1]],[[0,0],[1,0],[2,0],[1,1]],[[0,0],[0,1],[0,2],[1,2]],[[1,0],[1,1],[1,2],[0,2]],[[1,0],[2,0],[0,1],[1,1]],[[0,0],[1,0],[1,1],[2,1]]];
 let w=0,h=0,dpr=1,cols=0,rows=0,cell=28,grid=[],piece=null,last=0,acc=0,raf=0,paused=false,linesTotal=0,bag=[],clearBursts=[],sparks=[];
 const clone=s=>s.map(([x,y])=>[x,y]);
 const rotate=s=>{const max=Math.max(...s.map(p=>p[0]));return s.map(([x,y])=>[max-y,x])};
 const normalize=s=>{const minX=Math.min(...s.map(p=>p[0])),minY=Math.min(...s.map(p=>p[1]));return s.map(([x,y])=>[x-minX,y-minY])};
 const fits=(board,p,dx=0,dy=0,shape=p.shape)=>shape.every(([x,y])=>{const X=p.x+x+dx,Y=p.y+y+dy;return X>=0&&X<cols&&Y<rows&&(Y<0||!board[Y][X])});
 const scoreBoard=(board,cleared)=>{
  const heights=Array(cols).fill(0);let holes=0,aggregate=0,bump=0,wells=0;
  for(let x=0;x<cols;x++){let found=false;for(let y=0;y<rows;y++){if(board[y][x]){if(!found){heights[x]=rows-y;found=true}}else if(found)holes++}aggregate+=heights[x]}
  for(let x=0;x<cols-1;x++)bump+=Math.abs(heights[x]-heights[x+1]);
  for(let x=0;x<cols;x++){const left=x===0?rows:heights[x-1],right=x===cols-1?rows:heights[x+1],depth=Math.max(0,Math.min(left,right)-heights[x]);wells+=depth*(depth+1)/2}
  const top= Math.max(...heights);
  return aggregate*.48+holes*8.5+bump*.52+wells*1.35+top*.8-cleared*7.8;
 };
 const findMove=type=>{
  let best=null,bestScore=Infinity;
  let orientation=normalize(clone(shapes[type]));
  for(let rot=0;rot<4;rot++){
   const width=Math.max(...orientation.map(p=>p[0]))+1;
   for(let x=0;x<=cols-width;x++){
    const p={x,y:-4,shape:orientation};
    if(!fits(grid,p))continue;
    while(fits(grid,p,0,1))p.y++;
    const board=grid.map(row=>row.slice());let invalid=false;
    orientation.forEach(([sx,sy])=>{const yy=p.y+sy;if(yy<0)invalid=true;else board[yy][x+sx]=colors[type]});
    if(invalid)continue;
    let cleared=0;
    for(let y=rows-1;y>=0;y--)if(board[y].every(Boolean)){board.splice(y,1);board.unshift(Array(cols).fill(null));cleared++;y++}
    const score=scoreBoard(board,cleared)+(Math.random()*.035);
    if(score<bestScore){bestScore=score;best={x,shape:clone(orientation),type,cleared}}
   }
   orientation=normalize(rotate(orientation));
  }
  return best;
 };
 const drawType=()=>{
  if(!bag.length){bag=[0,1,2,3,4,5,6];for(let i=bag.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[bag[i],bag[j]]=[bag[j],bag[i]]}}
  return bag.pop();
 };
 const makePiece=()=>{
  const type=drawType();
  const move=findMove(type);
  if(!move){reset();return}
  const p={type,shape:normalize(clone(shapes[type])),x:Math.max(0,Math.floor(cols/2)-2),y:-3,color:colors[type],targetX:move.x,targetShape:move.shape,planned:false};
  piece=p;
 };
 const reset=()=>{grid=Array.from({length:rows},()=>Array(cols).fill(null));piece=null;makePiece()};
 const resize=()=>{const r=host.getBoundingClientRect();if(!r.width||!r.height)return;w=r.width;h=r.height;dpr=Math.min(devicePixelRatio||1,1.5);canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);cell=Math.max(19,Math.min(34,Math.round(w/Math.max(16,Math.floor(w/27)))));const nc=Math.max(12,Math.ceil(w/cell)),nr=Math.max(7,Math.ceil(h/cell));if(nc!==cols||nr!==rows){cols=nc;rows=nr;reset()}};
 const lock=()=>{
  let top=false;
  piece.shape.forEach(([x,y])=>{const X=piece.x+x,Y=piece.y+y;if(Y<0)top=true;else if(grid[Y])grid[Y][X]=piece.color});
  let cleared=0;
  for(let y=rows-1;y>=0;y--)if(grid[y].every(Boolean)){
   const rowColors=grid[y].slice();
   clearBursts.push({y,life:1});
   for(let x=0;x<cols;x++)for(let n=0;n<2;n++){
    const angle=Math.random()*Math.PI*2,speed=1.2+Math.random()*3.2;
    sparks.push({x:(x+.5)*cell,y:(y+.5)*cell,vx:Math.cos(angle)*speed,vy:Math.sin(angle)*speed-1.2,color:rowColors[x]||'#fff',life:.65+Math.random()*.45,size:1.5+Math.random()*2.5});
   }
   grid.splice(y,1);grid.unshift(Array(cols).fill(null));cleared++;y++
  }
  linesTotal+=cleared;
  if(top){reset();return}
  makePiece();
 };
 const block=(x,y,color,alpha=1)=>{const p=Math.max(1.5,cell*.065),bx=x*cell+p,by=y*cell+p,size=cell-p*2;ctx.save();ctx.globalAlpha=alpha;ctx.shadowColor=color;ctx.shadowBlur=cell*.3;const g=ctx.createLinearGradient(bx,by,bx+size,by+size);g.addColorStop(0,'#fff');g.addColorStop(.22,color);g.addColorStop(1,'#101a3a');ctx.fillStyle=g;ctx.beginPath();ctx.roundRect(bx,by,size,size,Math.max(3,cell*.14));ctx.fill();ctx.shadowBlur=0;ctx.strokeStyle=color;ctx.globalAlpha=alpha*.65;ctx.stroke();ctx.fillStyle='#fff';ctx.globalAlpha=alpha*.35;ctx.fillRect(bx+size*.16,by+size*.13,size*.66,Math.max(1,size*.07));ctx.restore()};
 const render=()=>{
  ctx.clearRect(0,0,w,h);
  const glow=ctx.createRadialGradient(w*.5,h*.48,4,w*.5,h*.48,Math.max(w,h)*.7);glow.addColorStop(0,'rgba(22,128,220,.16)');glow.addColorStop(1,'rgba(3,8,24,0)');ctx.fillStyle=glow;ctx.fillRect(0,0,w,h);
  ctx.strokeStyle='rgba(89,188,255,.105)';ctx.lineWidth=1;
  for(let x=0;x<=cols;x++){ctx.beginPath();ctx.moveTo(x*cell,0);ctx.lineTo(x*cell,h);ctx.stroke()}
  for(let y=0;y<=rows;y++){ctx.beginPath();ctx.moveTo(0,y*cell);ctx.lineTo(w,y*cell);ctx.stroke()}
  for(let y=0;y<rows;y++)for(let x=0;x<cols;x++)if(grid[y][x])block(x,y,grid[y][x],.48);
  if(piece)piece.shape.forEach(([x,y])=>{if(piece.y+y>=0)block(piece.x+x,piece.y+y,piece.color,.92)});
  clearBursts.forEach(fx=>{
   const alpha=Math.max(0,fx.life),yy=fx.y*cell;
   ctx.save();ctx.globalAlpha=alpha*.8;ctx.shadowColor='#fff';ctx.shadowBlur=22;
   const beam=ctx.createLinearGradient(0,yy,0,yy+cell);beam.addColorStop(0,'rgba(255,255,255,0)');beam.addColorStop(.5,'rgba(190,246,255,.95)');beam.addColorStop(1,'rgba(70,190,255,0)');
   ctx.fillStyle=beam;ctx.fillRect(0,yy-cell*.15,w,cell*1.3);
   ctx.fillStyle='rgba(255,255,255,.8)';ctx.fillRect(0,yy+cell*.43,w,Math.max(1,cell*.08));ctx.restore();
  });
  sparks.forEach(p=>{ctx.save();ctx.globalAlpha=Math.max(0,p.life);ctx.fillStyle=p.color;ctx.shadowColor=p.color;ctx.shadowBlur=10;ctx.beginPath();ctx.arc(p.x,p.y,p.size,0,Math.PI*2);ctx.fill();ctx.restore()});
  const t=performance.now()*.000025;for(let i=0;i<22;i++){const x=(i*97.3+t*19)%w,y=(i*53.7+t*31)%h;ctx.fillStyle='rgba(132,218,255,.22)';ctx.beginPath();ctx.arc(x,y,1+(i%3)*.45,0,Math.PI*2);ctx.fill()}
 };
 const step=()=>{
  if(!piece)return;
  // The little AI steers toward its best landing, turning and shifting while descending.
  if(!piece.planned){piece.shape=clone(piece.targetShape);piece.planned=true}
  if(piece.x!==piece.targetX){const dir=Math.sign(piece.targetX-piece.x);if(fits(grid,piece,dir,0))piece.x+=dir}
  if(fits(grid,piece,0,1))piece.y++;else lock();
 };
 const frame=now=>{raf=0;if(paused||reduce.matches)return;const dt=Math.min(50,now-(last||now));last=now;acc+=dt;if(acc>340){acc=0;step()}const decay=dt/700;clearBursts=clearBursts.filter(fx=>(fx.life-=decay)>0);sparks=sparks.filter(p=>{p.x+=p.vx*dt/16;p.y+=p.vy*dt/16;p.vy+=.12*dt/16;p.vx*=.985;return(p.life-=dt/850)>0});render();raf=requestAnimationFrame(frame)};
 const start=()=>{if(paused||reduce.matches||raf)return;last=0;raf=requestAnimationFrame(frame)};
 const stop=()=>{if(raf)cancelAnimationFrame(raf);raf=0};
 const observer=new ResizeObserver(resize);observer.observe(host);
 const io=new IntersectionObserver(entries=>{if(entries[0]?.isIntersecting)start();else stop()},{threshold:.02});io.observe(host);
 document.addEventListener('visibilitychange',()=>{paused=document.hidden;if(paused)stop();else start()});
 reduce.addEventListener?.('change',()=>{if(reduce.matches){stop();render()}else start()});
 resize();if(reduce.matches)render();else start();
})();
