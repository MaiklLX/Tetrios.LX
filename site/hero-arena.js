/* TETRIOS.LX — isolated decorative arena simulation */
(() => {
 const canvas=document.querySelector('#menu .hero-arena-canvas'), host=canvas?.parentElement;
 if(!canvas||!host)return;
 const ctx=canvas.getContext('2d',{alpha:true}); if(!ctx)return;
 const reduce=matchMedia('(prefers-reduced-motion: reduce)');
 const colors=['#36dfff','#9d75ff','#ffbd55','#63f5bd','#ff6f9f','#6e9cff','#d7f36b'];
 const shapes=[[[0,1],[1,1],[2,1],[3,1]],[[0,0],[1,0],[0,1],[1,1]],[[0,0],[1,0],[2,0],[1,1]],[[0,0],[0,1],[0,2],[1,2]],[[1,0],[1,1],[1,2],[0,2]],[[1,0],[2,0],[0,1],[1,1]],[[0,0],[1,0],[1,1],[2,1]]];
 let w=0,h=0,dpr=1,cols=0,rows=0,cell=28,grid=[],piece=null,last=0,acc=0,raf=0,paused=false;
 const makePiece=()=>{const t=Math.floor(Math.random()*7);return{type:t,shape:shapes[t].map(p=>p.slice()),x:Math.max(0,Math.floor(cols/2)-2),y:-2,color:colors[t]}};
 const fits=(p,dx=0,dy=0,shape=p.shape)=>shape.every(([x,y])=>{const X=p.x+x+dx,Y=p.y+y+dy;return X>=0&&X<cols&&Y<rows&&(Y<0||!grid[Y][X])});
 const rotate=s=>{const max=Math.max(...s.map(p=>p[0]));return s.map(([x,y])=>[max-y,x])};
 const reset=()=>{grid=Array.from({length:rows},()=>Array(cols).fill(null));piece=makePiece()};
 const resize=()=>{const r=host.getBoundingClientRect();if(!r.width||!r.height)return;w=r.width;h=r.height;dpr=Math.min(devicePixelRatio||1,1.5);canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);cell=Math.max(19,Math.min(34,Math.round(w/Math.max(16,Math.floor(w/27)))));const nc=Math.max(12,Math.ceil(w/cell)),nr=Math.max(7,Math.ceil(h/cell));if(nc!==cols||nr!==rows){cols=nc;rows=nr;reset()}};
 const lock=()=>{let top=false;piece.shape.forEach(([x,y])=>{const X=piece.x+x,Y=piece.y+y;if(Y<0)top=true;else if(grid[Y])grid[Y][X]=piece.color});for(let y=rows-1;y>=0;y--){if(grid[y].every(Boolean)){grid.splice(y,1);grid.unshift(Array(cols).fill(null));y++}}if(top)reset();else piece=makePiece()};
 const block=(x,y,color,alpha=1)=>{const p=Math.max(1.5,cell*.065),bx=x*cell+p,by=y*cell+p,size=cell-p*2;ctx.save();ctx.globalAlpha=alpha;ctx.shadowColor=color;ctx.shadowBlur=cell*.3;const g=ctx.createLinearGradient(bx,by,bx+size,by+size);g.addColorStop(0,'#fff');g.addColorStop(.22,color);g.addColorStop(1,'#101a3a');ctx.fillStyle=g;ctx.beginPath();ctx.roundRect(bx,by,size,size,Math.max(3,cell*.14));ctx.fill();ctx.shadowBlur=0;ctx.strokeStyle=color;ctx.globalAlpha=alpha*.65;ctx.stroke();ctx.fillStyle='#fff';ctx.globalAlpha=alpha*.35;ctx.fillRect(bx+size*.16,by+size*.13,size*.66,Math.max(1,size*.07));ctx.restore()};
 const render=()=>{ctx.clearRect(0,0,w,h);const glow=ctx.createRadialGradient(w*.5,h*.48,4,w*.5,h*.48,Math.max(w,h)*.7);glow.addColorStop(0,'rgba(22,128,220,.16)');glow.addColorStop(1,'rgba(3,8,24,0)');ctx.fillStyle=glow;ctx.fillRect(0,0,w,h);ctx.strokeStyle='rgba(89,188,255,.105)';ctx.lineWidth=1;for(let x=0;x<=cols;x++){ctx.beginPath();ctx.moveTo(x*cell,0);ctx.lineTo(x*cell,h);ctx.stroke()}for(let y=0;y<=rows;y++){ctx.beginPath();ctx.moveTo(0,y*cell);ctx.lineTo(w,y*cell);ctx.stroke()}for(let y=0;y<rows;y++)for(let x=0;x<cols;x++)if(grid[y][x])block(x,y,grid[y][x],.48);if(piece)piece.shape.forEach(([x,y])=>{if(piece.y+y>=0)block(piece.x+x,piece.y+y,piece.color,.9)});const t=performance.now()*.000025;for(let i=0;i<22;i++){const x=(i*97.3+t*19)%w,y=(i*53.7+t*31)%h;ctx.fillStyle='rgba(132,218,255,.22)';ctx.beginPath();ctx.arc(x,y,1+(i%3)*.45,0,Math.PI*2);ctx.fill()}};
 const frame=now=>{raf=0;if(paused||reduce.matches)return;const dt=Math.min(50,now-(last||now));last=now;acc+=dt;if(acc>390){acc=0;if(piece){if(fits(piece,0,1))piece.y++;else lock();if(Math.random()<.12){const rotated=rotate(piece.shape);if(fits(piece,0,0,rotated))piece.shape=rotated}}}render();raf=requestAnimationFrame(frame)};
 const start=()=>{if(paused||reduce.matches||raf)return;last=0;raf=requestAnimationFrame(frame)};
 const stop=()=>{if(raf)cancelAnimationFrame(raf);raf=0};
 const observer=new ResizeObserver(resize);observer.observe(host);
 const io=new IntersectionObserver(entries=>{if(entries[0]?.isIntersecting)start();else stop()},{threshold:.02});io.observe(host);
 document.addEventListener('visibilitychange',()=>{paused=document.hidden;if(paused)stop();else start()});
 reduce.addEventListener?.('change',()=>{if(reduce.matches){stop();render()}else start()});
 resize();if(reduce.matches)render();else start();
})();
