/* Tetrios.LX — lightweight real-time 3D hero viewer. Three.js / WebGL, with graceful emoji fallback. */
(async function(){
  const THREE_URL='https://cdn.jsdelivr.net/npm/three@0.180.0/build/three.module.js';
  let THREE;
  try{THREE=await import(THREE_URL)}catch(err){
    console.warn('[Tetrios 3D] Three.js unavailable; keeping fallback artwork.',err);
    const fallbackScan=()=>document.querySelectorAll('.bb-3d-stage').forEach(stage=>{
      if(stage.querySelector('.bb-3d-fallback'))return;
      const fallback=document.createElement('div');fallback.className='bb-3d-fallback';fallback.textContent=stage.dataset.heroEmoji||'🧸';stage.appendChild(fallback);
    });
    fallbackScan();new MutationObserver(fallbackScan).observe(document.body,{childList:true,subtree:true});return;
  }
  const active=new Map();
  const colorFor=id=>({plush:0x8e9bff,ember:0xff855b,spark:0xffca56,slime:0x67f3c5,void:0xa18aff}[id]||0x8e9bff);
  const mat=(color,roughness=.32,metalness=.12,emissive=0x000000)=>new THREE.MeshStandardMaterial({color,roughness,metalness,emissive,emissiveIntensity:.38});
  function roundedBlock(w,h,d,r,material){
    const shape=new THREE.Shape();const x=-w/2,y=-h/2;
    shape.moveTo(x+r,y);shape.lineTo(x+w-r,y);shape.quadraticCurveTo(x+w,y,x+w,y+r);
    shape.lineTo(x+w,y+h-r);shape.quadraticCurveTo(x+w,y+h,x+w-r,y+h);
    shape.lineTo(x+r,y+h);shape.quadraticCurveTo(x,y+h,x,y+h-r);
    shape.lineTo(x,y+r);shape.quadraticCurveTo(x,y,x+r,y);
    const geo=new THREE.ExtrudeGeometry(shape,{depth:d-2*r,bevelEnabled:true,bevelSegments:3,steps:1,bevelSize:r*.58,bevelThickness:r*.55,curveSegments:5});
    geo.translate(0,0,-(d-2*r)/2);return new THREE.Mesh(geo,material);
  }
  function makeCharacter(stage){
    const id=stage.dataset.heroId||'plush',base=colorFor(id),group=new THREE.Group();
    const bodyMat=mat(base,.28,.16,base),darkMat=mat(0x151c3b,.24,.2),eyeMat=mat(0xf4ffff,.18,.05,0x6bfdf4),glowMat=new THREE.MeshBasicMaterial({color:base});
    const body=roundedBlock(1.1,1.08,.78,.16,bodyMat);body.position.y=.92;group.add(body);
    const belly=new THREE.Mesh(new THREE.SphereGeometry(.31,24,18),mat(0xd9e6ff,.24,.04));belly.scale.set(1,.78,.22);belly.position.set(0,.83,.405);group.add(belly);
    for(const x of [-.24,.24]){
      const eye=new THREE.Mesh(new THREE.SphereGeometry(.105,18,14),eyeMat);eye.position.set(x,1.12,.415);group.add(eye);
      const pupil=new THREE.Mesh(new THREE.SphereGeometry(.045,14,10),darkMat);pupil.position.set(x+.018,1.11,.505);group.add(pupil);
    }
    const mouth=new THREE.Mesh(new THREE.BoxGeometry(.17,.035,.025),darkMat);mouth.position.set(0,.91,.514);group.add(mouth);
    for(const side of [-1,1]){
      const arm=roundedBlock(.24,.65,.25,.07,mat(base===0xff855b?0xd95b4d:base===0xffca56?0xd88b35:base===0x67f3c5?0x2cae9a:0x5b68c8,.3,.15));
      arm.position.set(side*.68,.88,0);arm.rotation.z=side*.12;group.add(arm);
      const hand=new THREE.Mesh(new THREE.SphereGeometry(.15,16,12),bodyMat);hand.position.set(side*.73,.52,.02);group.add(hand);
      const foot=roundedBlock(.34,.2,.38,.055,darkMat);foot.position.set(side*.28,.2,.03);group.add(foot);
    }
    const crest=new THREE.Mesh(new THREE.ConeGeometry(.18,.3,5),mat(0xf4d47c,.25,.3,0x745020));crest.position.set(0,1.57,0);crest.rotation.y=.4;group.add(crest);
    const halo=new THREE.Mesh(new THREE.TorusGeometry(.72,.025,8,64),new THREE.MeshBasicMaterial({color:base,transparent:true,opacity:.72}));halo.rotation.x=Math.PI/2;halo.position.y=.12;group.add(halo);
    const ring2=new THREE.Mesh(new THREE.TorusGeometry(.9,.009,6,64),new THREE.MeshBasicMaterial({color:0x9baeff,transparent:true,opacity:.42}));ring2.rotation.x=Math.PI/2;ring2.position.y=.08;group.add(ring2);
    const sparkles=new THREE.Group();
    for(let i=0;i<18;i++){const a=i*2.399,rad=.92+(i%3)*.14;const p=new THREE.Mesh(new THREE.OctahedronGeometry(i%4===0?.045:.022),glowMat);p.position.set(Math.cos(a)*rad,.35+(i%5)*.27,Math.sin(a)*rad*.55);sparkles.add(p)}
    group.add(sparkles);
    if(id==='ember'){const flame=new THREE.Mesh(new THREE.ConeGeometry(.18,.4,8),mat(0xff7b47,.25,.05,0xff3d16));flame.position.set(0,1.8,0);group.add(flame)}
    if(id==='spark'){const bolt=new THREE.Mesh(new THREE.OctahedronGeometry(.19),mat(0xffe17a,.2,.25,0xffad28));bolt.position.set(.58,1.55,0);bolt.rotation.z=.25;group.add(bolt)}
    if(id==='void'){const crown=new THREE.Mesh(new THREE.TorusGeometry(.34,.07,5,5),mat(0xc6a5ff,.22,.45,0x5932aa));crown.position.y=1.62;crown.rotation.x=.2;group.add(crown)}
    group.scale.setScalar(1.02);return {group,halo,ring2,sparkles};
  }
  function mount(stage){
    if(stage.dataset.bb3dReady==='1')return;
    stage.dataset.bb3dReady='1';
    const fallback=document.createElement('div');fallback.className='bb-3d-fallback';fallback.textContent=stage.dataset.heroEmoji||'🧸';stage.appendChild(fallback);
    try{
      const scene=new THREE.Scene();const camera=new THREE.PerspectiveCamera(34,1,.1,100);camera.position.set(0,1.5,5.8);camera.lookAt(0,.9,0);
      const renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,powerPreference:'low-power'});renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,2));renderer.setSize(stage.clientWidth||320,stage.clientHeight||220,false);renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;
      renderer.domElement.setAttribute('aria-label','Объёмная 3D-модель персонажа');renderer.domElement.setAttribute('role','img');stage.insertBefore(renderer.domElement,fallback);fallback.style.display='none';
      scene.add(new THREE.HemisphereLight(0xc6d8ff,0x1a1c42,2.1));
      const key=new THREE.DirectionalLight(0xffffff,3.2);key.position.set(3,5,4);scene.add(key);
      const rim=new THREE.PointLight(colorFor(stage.dataset.heroId),16,8);rim.position.set(-2,2,2);scene.add(rim);
      const floor=new THREE.Mesh(new THREE.CircleGeometry(1.35,48),new THREE.MeshBasicMaterial({color:colorFor(stage.dataset.heroId),transparent:true,opacity:.09,side:THREE.DoubleSide}));floor.rotation.x=-Math.PI/2;floor.position.y=.02;scene.add(floor);
      const char=makeCharacter(stage);scene.add(char.group);
      const caption=document.createElement('div');caption.className='bb-3d-caption';caption.textContent='3D HERO PREVIEW · WEBGL';stage.appendChild(caption);
      const resize=()=>{if(!stage.isConnected)return;const w=Math.max(1,stage.clientWidth),h=Math.max(1,stage.clientHeight);renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix()};
      const ro=new ResizeObserver(resize);ro.observe(stage);
      active.set(stage,{renderer,scene,camera,char,ro});
    }catch(err){console.warn('[Tetrios 3D] Renderer failed; keeping fallback artwork.',err);fallback.style.display='';}
  }
  function scan(){document.querySelectorAll('.bb-3d-stage').forEach(mount);for(const [stage,item] of active){if(!stage.isConnected){item.ro.disconnect();item.renderer.dispose();active.delete(stage)}}}
  const clock=new THREE.Clock();
  function frame(){requestAnimationFrame(frame);const t=clock.getElapsedTime();scan();for(const [stage,item] of active){if(stage.offsetParent===null)continue;item.char.group.position.y=Math.sin(t*1.8)*.065;item.char.group.rotation.y=Math.sin(t*.55)*.2;item.char.halo.rotation.z=t*.38;item.char.ring2.rotation.z=-t*.22;item.char.sparkles.rotation.y=t*.28;item.renderer.render(item.scene,item.camera)}}
  new MutationObserver(scan).observe(document.body,{childList:true,subtree:true});scan();frame();
})();