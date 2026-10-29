/* Tetrios.LX — optional real-time 3D board renderer. The original 2D canvas remains the game/input source. */
(async function(){
  const frame=document.querySelector('.boardframe');
  const boardCanvas=document.getElementById('board');
  if(!frame||!boardCanvas)return;
  const toggle=document.createElement('button');
  toggle.type='button';toggle.className='bb-arena-toggle';toggle.textContent='3D ARENA';
  toggle.setAttribute('aria-pressed','false');
  toggle.title='Переключить объёмное игровое поле';
  frame.appendChild(toggle);
  let THREE;
  try{THREE=await import('https://cdn.jsdelivr.net/npm/three@0.180.0/build/three.module.js')}
  catch(error){toggle.title='Для 3D-режима требуется загрузка Three.js';toggle.addEventListener('click',()=>{toggle.textContent='3D НЕДОСТУПНО';setTimeout(()=>toggle.textContent='3D ARENA',1800)});return}
  let renderer,scene,camera,boardGroup,activeGroup,ghostGroup,gridGroup,effectsGroup,resizeObserver,enabled=false,lastBoardSignature='',lastPieceSignature='',raf=0,previousState=null,lastSyncAt=0,pieceOffsetY=0,lastClearAt=0,clearStreak=0;
  const colorCache=new Map();
  const materialFor=(color,ghost=false)=>{
    const key=String(color)+':'+ghost;
    if(!colorCache.has(key))colorCache.set(key,new THREE.MeshStandardMaterial({
      color,roughness:ghost?.4:.26,metalness:ghost?.18:.35,
      emissive:color,emissiveIntensity:ghost?.12:.22,
      transparent:ghost,opacity:ghost?.2:1
    }));
    return colorCache.get(key);
  };
  function init(){
    if(renderer)return;
    scene=new THREE.Scene();scene.background=null;
    camera=new THREE.PerspectiveCamera(37,1,.1,100);
    camera.position.set(3.0,2.0,34);camera.lookAt(0,0,0);
    renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,powerPreference:'high-performance'});
    renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,1.35));
    renderer.outputColorSpace=THREE.SRGBColorSpace;
    renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;
    renderer.domElement.className='bb-arena-canvas';renderer.domElement.setAttribute('aria-hidden','true');
    frame.insertBefore(renderer.domElement,boardCanvas.nextSibling);
    scene.add(new THREE.HemisphereLight(0xb9d7ff,0x11182e,2.3));
    const key=new THREE.DirectionalLight(0xffffff,3.1);key.position.set(-4,7,12);scene.add(key);
    const rim=new THREE.PointLight(0x45f4ff,18,28);rim.position.set(5,0,8);scene.add(rim);
    const violet=new THREE.PointLight(0x9566ff,13,24);violet.position.set(-6,2,-4);scene.add(violet);
    const shell=new THREE.Mesh(new THREE.BoxGeometry(10.25,20.45,.78),new THREE.MeshStandardMaterial({color:0x101a34,roughness:.3,metalness:.82,emissive:0x111c3c,emissiveIntensity:.55}));
    shell.position.set(0,0,-.62);scene.add(shell);
    const plane=new THREE.Mesh(new THREE.PlaneGeometry(9.9,19.9),new THREE.MeshStandardMaterial({color:0x0b1429,roughness:.34,metalness:.28,transparent:true,opacity:.96}));
    plane.position.z=-.18;scene.add(plane);
    const inset=new THREE.Mesh(new THREE.PlaneGeometry(9.55,19.55),new THREE.MeshBasicMaterial({color:0x102341,transparent:true,opacity:.24}));
    inset.position.z=-.15;scene.add(inset);
    const sideGlowMat=new THREE.MeshBasicMaterial({color:0x54fff0,transparent:true,opacity:.32});
    [-5.06,5.06].forEach(x=>{const glow=new THREE.Mesh(new THREE.BoxGeometry(.035,19.8,.04),sideGlowMat);glow.position.set(x,0,-.08);scene.add(glow)});
    const topGlow=new THREE.Mesh(new THREE.BoxGeometry(10.12,.035,.04),new THREE.MeshBasicMaterial({color:0xa98aff,transparent:true,opacity:.55}));
    topGlow.position.set(0,10.02,-.08);scene.add(topGlow);
    gridGroup=new THREE.Group();scene.add(gridGroup);
    const lineMaterial=new THREE.LineBasicMaterial({color:0x385477,transparent:true,opacity:.55});
    const positions=[];
    for(let x=0;x<=10;x++){const px=x-5;positions.push(px,-10,.01,px,10,.01)}
    for(let y=0;y<=20;y++){const py=10-y;positions.push(-5,py,.01,5,py,.01)}
    const gridGeo=new THREE.BufferGeometry();gridGeo.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));
    gridGroup.add(new THREE.LineSegments(gridGeo,lineMaterial));
    const borderGeo=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-5,-10,.04),new THREE.Vector3(5,-10,.04),new THREE.Vector3(5,10,.04),new THREE.Vector3(-5,10,.04),new THREE.Vector3(-5,-10,.04)]);
    gridGroup.add(new THREE.Line(borderGeo,new THREE.LineBasicMaterial({color:0x75fff0,transparent:true,opacity:.8})));
    // Floating side rails and corner beacons give the board a framed arcade-arena silhouette.
    const railMat=new THREE.MeshStandardMaterial({color:0x5df8ee,emissive:0x1a8e9c,emissiveIntensity:1.6,metalness:.65,roughness:.22});
    const railGeo=new THREE.BoxGeometry(.075,20.6,.16);
    [-5.34,5.34].forEach((x,i)=>{
      const rail=new THREE.Mesh(railGeo,railMat);rail.position.set(x,0,-.04);gridGroup.add(rail);
      const beaconGeo=new THREE.SphereGeometry(.105,12,8);
      [-10.15,10.15].forEach(y=>{const beacon=new THREE.Mesh(beaconGeo,new THREE.MeshBasicMaterial({color:i?0xa98aff:0x75fff0}));beacon.position.set(x,y,.12);gridGroup.add(beacon)});
    });
    const base=new THREE.Mesh(new THREE.BoxGeometry(10.9,.16,.65),new THREE.MeshStandardMaterial({color:0x182442,metalness:.8,roughness:.28,emissive:0x101e42,emissiveIntensity:.7}));
    base.position.set(0,-10.48,-.12);gridGroup.add(base);
    boardGroup=new THREE.Group();scene.add(boardGroup);
    activeGroup=new THREE.Group();scene.add(activeGroup);
    ghostGroup=new THREE.Group();scene.add(ghostGroup);
    effectsGroup=new THREE.Group();scene.add(effectsGroup);
    const resize=()=>{if(!renderer)return;const w=Math.max(1,frame.clientWidth-14),h=Math.max(1,frame.clientHeight-14);renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix()};
    resizeObserver=new ResizeObserver(resize);resizeObserver.observe(frame);resize();
  }
  function blockInto(target,x,y,color,ghost=false){
    const cell=new THREE.Group();
    cell.position.set(x-4.5,9.5-y,ghost?.03:.24);
    cell.userData.pulsePhase=(x*7+y*13)%19;
    const geo=new THREE.BoxGeometry(.88,.88,.62);
    const mesh=new THREE.Mesh(geo,materialFor(color,ghost));
    cell.add(mesh);
    const edges=new THREE.LineSegments(new THREE.EdgesGeometry(geo),new THREE.LineBasicMaterial({color:ghost?0x91eaff:0xe6ffff,transparent:true,opacity:ghost?.3:.7}));
    edges.position.z=.002;cell.add(edges);
    if(!ghost){
      const shine=new THREE.Mesh(new THREE.BoxGeometry(.66,.045,.018),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.5}));
      shine.position.set(0,.31,.325);cell.add(shine);
      const accent=new THREE.Mesh(new THREE.BoxGeometry(.055,.58,.025),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.42}));
      accent.position.set(-.32,-.08,.326);cell.add(accent);
      const corner=new THREE.Mesh(new THREE.BoxGeometry(.16,.045,.025),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.5}));
      corner.position.set(.27,-.31,.326);cell.add(corner);
    }
    target.add(cell);
  }
  function disposeGroup(group){
    group.traverse(obj=>{
      if(obj.geometry)obj.geometry.dispose();
      if(obj.material){
        const list=Array.isArray(obj.material)?obj.material:[obj.material];
        for(const m of list)if(!Array.from(colorCache.values()).includes(m))m.dispose();
      }
    });
    group.clear();
  }
  function sync(){
    if(!enabled||!window.bbGet3DBoardState)return;
    const state=window.bbGet3DBoardState();
    if(previousState&&Number.isFinite(state.lines)&&Number.isFinite(previousState.lines)&&state.lines>previousState.lines){
      const now=performance.now(),count=Math.min(4,state.lines-previousState.lines);
      clearStreak=now-lastClearAt<1800?Math.min(5,clearStreak+1):1;lastClearAt=now;
      for(const obj of [...effectsGroup.children]){
        effectsGroup.remove(obj);if(obj.geometry)obj.geometry.dispose();if(obj.material)obj.material.dispose();
      }
      for(let n=0;n<count;n++){
        const mat=new THREE.MeshBasicMaterial({color:n%2?0xa98aff:0x9ffff8,transparent:true,opacity:.98,side:THREE.DoubleSide});
        const flash=new THREE.Mesh(new THREE.PlaneGeometry(10,.72),mat);
        flash.position.set(0,-9.15+n*.72,.48);flash.userData.createdAt=now;flash.userData.life=460+clearStreak*90;flash.userData.clearFlash=true;
        effectsGroup.add(flash);
      }
      // A short radial burst makes consecutive clears feel stronger without changing scoring.
      const particleCount=Math.min(36,12+count*4+clearStreak*3);
      for(let i=0;i<particleCount;i++){
        const angle=(Math.PI*2*i/particleCount)+(Math.random()-.5)*.12;
        const speed=.035+Math.random()*.055;
        const mat=new THREE.MeshBasicMaterial({color:i%3===0?0xffd47a:(i%2?0xa98aff:0x75fff0),transparent:true,opacity:.95});
        const particle=new THREE.Mesh(new THREE.SphereGeometry(.035+Math.random()*.035,6,5),mat);
        particle.position.set(Math.cos(angle)*2.8,(Math.random()-.5)*13,.55);
        particle.userData.createdAt=now;particle.userData.life=520+clearStreak*110;
        particle.userData.velocity={x:Math.cos(angle)*speed,y:Math.sin(angle)*speed};
        effectsGroup.add(particle);
      }
    }
    const boardSignature=JSON.stringify([state.board,state.colors]);
    const boardChanged=boardSignature!==lastBoardSignature;
    const linesChanged=!!previousState&&Number.isFinite(state.lines)&&Number.isFinite(previousState.lines)&&state.lines>previousState.lines;
    // A locked piece becomes part of the settled board. Brief cell flashes make that transition readable.
    if(boardChanged&&previousState?.piece&&!linesChanged){
      const oldPiece=previousState.piece;
      oldPiece.shape.forEach((row,dy)=>row.forEach((v,dx)=>{
        if(!v||oldPiece.y+dy<0)return;
        const mat=new THREE.MeshBasicMaterial({color:0x8ffff7,transparent:true,opacity:.72,side:THREE.DoubleSide});
        const flash=new THREE.Mesh(new THREE.PlaneGeometry(.82,.82),mat);
        flash.position.set(oldPiece.x+dx-4.5,9.5-(oldPiece.y+dy),.52);
        flash.userData.createdAt=performance.now();
        effectsGroup.add(flash);
      }));
    }
    if(boardChanged){
      lastBoardSignature=boardSignature;
      disposeGroup(boardGroup);
      const colors=state.colors||[];
      for(let y=0;y<state.height;y++)for(let x=0;x<state.width;x++){
        const v=state.board[y]?.[x];if(v)blockInto(boardGroup,x,y,colors[v-1]||'#69f4ff');
      }
    }
    const pieceSignature=JSON.stringify([state.piece,state.ghostY,state.colors]);
    if(pieceSignature!==lastPieceSignature){
      lastPieceSignature=pieceSignature;
      const oldPiece=previousState?.piece,newPiece=state.piece;
      pieceOffsetY=oldPiece&&newPiece&&oldPiece.t===newPiece.t&&oldPiece.x===newPiece.x&&
        JSON.stringify(oldPiece.shape)===JSON.stringify(newPiece.shape)&&
        newPiece.y>oldPiece.y&&newPiece.y-oldPiece.y<=2 ? newPiece.y-oldPiece.y : 0;
      disposeGroup(activeGroup);disposeGroup(ghostGroup);
      const colors=state.colors||[];
      if(newPiece){
        const p=newPiece,color=colors[p.t]||'#69f4ff';
        if(Number.isFinite(state.ghostY))p.shape.forEach((row,dy)=>row.forEach((v,dx)=>{if(v&&state.ghostY+dy>=0)blockInto(ghostGroup,p.x+dx,state.ghostY+dy,color,true)}));
        p.shape.forEach((row,dy)=>row.forEach((v,dx)=>{if(v&&p.y+dy>=0)blockInto(activeGroup,p.x+dx,p.y+dy,color)}));
      }
      activeGroup.position.y=pieceOffsetY;
    }
    previousState={...state,board:state.board?.map(row=>row.slice())};
  }
  function animate(){
    raf=0;
    if(!enabled||!renderer||document.hidden)return;
    const now=performance.now();
    // The board changes only on input/tick events; syncing at ~25 Hz keeps the 60 Hz render loop light.
    if(now-lastSyncAt>=40){sync();lastSyncAt=now;}
    if(effectsGroup){
      for(const effect of [...effectsGroup.children]){
        const age=now-(effect.userData.createdAt||now),life=effect.userData.life||460;
        const progress=Math.min(1,age/life);
        effect.material.opacity=(1-progress)*.95;
        if(effect.userData.velocity){
          effect.position.x+=effect.userData.velocity.x;
          effect.position.y+=effect.userData.velocity.y;
          effect.scale.setScalar(1-progress*.7);
        }else{
          effect.scale.set(1+progress*.16,1+progress*.22,1);
        }
        if(progress>=1){effectsGroup.remove(effect);effect.geometry.dispose();effect.material.dispose();}
      }
    }
    if(!window.matchMedia('(prefers-reduced-motion: reduce)').matches){
      const t=now*.00025;camera.position.x=3+Math.sin(t)*.12;camera.position.y=2+Math.cos(t*.8)*.05;
      [boardGroup,activeGroup,ghostGroup].forEach(group=>group.children.forEach(cell=>{if(cell.isGroup){const pulse=1+Math.sin(now*.004+cell.userData.pulsePhase)*.008;cell.scale.set(pulse,pulse,1);}}));
      if(pieceOffsetY){pieceOffsetY*=Math.exp(-Math.min(.05,1/60)*18);if(Math.abs(pieceOffsetY)<.015)pieceOffsetY=0;activeGroup.position.y=pieceOffsetY;}
    }
    camera.lookAt(0,0,0);renderer.render(scene,camera);
    raf=requestAnimationFrame(animate);
  }
  function setEnabled(next){
    enabled=!!next;
    toggle.setAttribute('aria-pressed',String(enabled));
    toggle.textContent=enabled?'2D РЕЖИМ':'3D ARENA';
    frame.classList.toggle('bb-3d-arena-active',enabled);
    if(!enabled&&raf){cancelAnimationFrame(raf);raf=0;}
    if(enabled){
      try{init();sync();lastSyncAt=performance.now();if(!raf)animate()}
      catch(error){enabled=false;frame.classList.remove('bb-3d-arena-active');toggle.setAttribute('aria-pressed','false');toggle.textContent='3D НЕДОСТУПНО';console.warn('[Tetrios 3D arena] WebGL unavailable; returning to 2D.',error);setTimeout(()=>{toggle.textContent='3D ARENA'},2200)}
    }
  }
  toggle.addEventListener('click',()=>{
    setEnabled(!enabled);
  });
  const gameScreen=document.getElementById('game');
  if(gameScreen){
    const gameObserver=new MutationObserver(()=>{
      const visible=!gameScreen.hidden;
      if(visible&&!enabled)setEnabled(true);
      else if(!visible&&enabled)setEnabled(false);
    });
    gameObserver.observe(gameScreen,{attributes:true,attributeFilter:['hidden']});
    if(!gameScreen.hidden)setEnabled(true);
  }
  document.addEventListener('visibilitychange',()=>{if(document.hidden&&raf){cancelAnimationFrame(raf);raf=0;}else if(!document.hidden&&enabled){sync();lastSyncAt=performance.now();if(!raf)animate();}});
})();