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
  let renderer,scene,camera,boardGroup,gridGroup,glowGroup,resizeObserver,enabled=false,lastSignature='',raf=0;
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
    camera.position.set(3.2,3.6,27);camera.lookAt(0,0,0);
    renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,powerPreference:'high-performance'});
    renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,1.5));
    renderer.outputColorSpace=THREE.SRGBColorSpace;
    renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;
    renderer.domElement.className='bb-arena-canvas';renderer.domElement.setAttribute('aria-hidden','true');
    frame.insertBefore(renderer.domElement,boardCanvas.nextSibling);
    scene.add(new THREE.HemisphereLight(0xb9d7ff,0x11182e,2.3));
    const key=new THREE.DirectionalLight(0xffffff,3.1);key.position.set(-4,7,12);scene.add(key);
    const rim=new THREE.PointLight(0x45f4ff,18,28);rim.position.set(5,0,8);scene.add(rim);
    const violet=new THREE.PointLight(0x9566ff,13,24);violet.position.set(-6,2,-4);scene.add(violet);
    const plane=new THREE.Mesh(new THREE.PlaneGeometry(9.6,19.2),new THREE.MeshStandardMaterial({color:0x0b1429,roughness:.44,metalness:.2,transparent:true,opacity:.88}));
    plane.position.z=-.5;scene.add(plane);
    gridGroup=new THREE.Group();scene.add(gridGroup);
    const lineMaterial=new THREE.LineBasicMaterial({color:0x385477,transparent:true,opacity:.55});
    const positions=[];
    for(let x=0;x<=10;x++){const px=x-5;positions.push(px,-10,.01,px,10,.01)}
    for(let y=0;y<=20;y++){const py=10-y;positions.push(-5,py,.01,5,py,.01)}
    const gridGeo=new THREE.BufferGeometry();gridGeo.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));
    gridGroup.add(new THREE.LineSegments(gridGeo,lineMaterial));
    const borderGeo=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-5,-10,.04),new THREE.Vector3(5,-10,.04),new THREE.Vector3(5,10,.04),new THREE.Vector3(-5,10,.04),new THREE.Vector3(-5,-10,.04)]);
    gridGroup.add(new THREE.Line(borderGeo,new THREE.LineBasicMaterial({color:0x75fff0,transparent:true,opacity:.8})));
    boardGroup=new THREE.Group();scene.add(boardGroup);
    const resize=()=>{if(!renderer)return;const w=Math.max(1,frame.clientWidth-14),h=Math.max(1,frame.clientHeight-14);renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix()};
    resizeObserver=new ResizeObserver(resize);resizeObserver.observe(frame);resize();
  }
  function block(x,y,color,ghost=false){
    const geo=new THREE.BoxGeometry(.88,.88,.42);
    const mesh=new THREE.Mesh(geo,materialFor(color,ghost));
    mesh.position.set(x-4.5,9.5-y,ghost?.02:.22);
    if(!ghost){mesh.castShadow=false;mesh.receiveShadow=false}
    boardGroup.add(mesh);
    const edges=new THREE.LineSegments(new THREE.EdgesGeometry(geo),new THREE.LineBasicMaterial({color:0xe6ffff,transparent:true,opacity:ghost?.35:.62}));
    edges.position.copy(mesh.position);boardGroup.add(edges);
    if(!ghost){const shine=new THREE.Mesh(new THREE.BoxGeometry(.68,.055,.018),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.32}));shine.position.set(mesh.position.x,mesh.position.y+.31,mesh.position.z+.22);boardGroup.add(shine)}
  }
  function sync(){
    if(!enabled||!window.bbGet3DBoardState)return;
    const state=window.bbGet3DBoardState();
    const signature=JSON.stringify(state);
    if(signature===lastSignature)return;
    lastSignature=signature;
    boardGroup.clear();
    const colors=state.colors||[];
    for(let y=0;y<state.height;y++)for(let x=0;x<state.width;x++){
      const v=state.board[y]?.[x];if(v)block(x,y,colors[v-1]||'#69f4ff');
    }
    if(state.piece){
      const p=state.piece,color=colors[p.t]||'#69f4ff';
      p.shape.forEach((row,dy)=>row.forEach((v,dx)=>{if(v&&p.y+dy>=0)block(p.x+dx,p.y+dy,color)}));
      if(Number.isFinite(state.ghostY))p.shape.forEach((row,dy)=>row.forEach((v,dx)=>{if(v&&state.ghostY+dy>=0)block(p.x+dx,state.ghostY+dy,color,true)}));
    }
  }
  function animate(){
    raf=requestAnimationFrame(animate);
    if(!enabled||!renderer||document.hidden)return;
    sync();const t=performance.now()*.00025;
    camera.position.x=3.2+Math.sin(t)*.18;camera.lookAt(0,0,0);
    renderer.render(scene,camera);
  }
  toggle.addEventListener('click',()=>{
    enabled=!enabled;
    toggle.setAttribute('aria-pressed',String(enabled));
    toggle.textContent=enabled?'2D РЕЖИМ':'3D ARENA';
    frame.classList.toggle('bb-3d-arena-active',enabled);
    if(enabled){init();sync();if(!raf)animate()}
  });
  document.addEventListener('visibilitychange',()=>{if(!document.hidden&&enabled)sync()});
})();