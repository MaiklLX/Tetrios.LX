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
  const colorFor=id=>({plush:0x9b6845,prism:0x42c8ff,blip:0x9564f5,pixel:0x42d6a0,spark:0xffc84d}[id]||0x8e9bff);
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
  function addEyes(group,positions,eyeMat,pupilMat){
    positions.forEach(([x,y,z,scale=1])=>{
      const eye=new THREE.Mesh(new THREE.SphereGeometry(.09*scale,18,14),eyeMat);eye.position.set(x,y,z);group.add(eye);
      const pupil=new THREE.Mesh(new THREE.SphereGeometry(.038*scale,14,10),pupilMat);pupil.position.set(x+.018*scale,y-.008*scale,z+.065*scale);group.add(pupil);
    });
  }
  function makeCharacter(stage){
    const id=stage.dataset.heroId||'plush',base=colorFor(id),group=new THREE.Group();
    const darkMat=mat(0x151c3b,.24,.2),eyeMat=mat(0xf4ffff,.18,.05,0x6bfdf4),metalMat=mat(0xb7c8ed,.22,.72),goldMat=mat(0xffd56f,.24,.48,0x5a3308);
    const bodyMat=mat(base,.28,.16,base),glowMat=new THREE.MeshBasicMaterial({color:base});
    const sparkles=new THREE.Group();
    // Five distinct silhouettes: teddy guardian, faceted crystal, mischievous alien,
    // compact robot and electric striker. Shared only the scene lighting/animation.
    if(id==='plush'){
      const torso=new THREE.Mesh(new THREE.SphereGeometry(.57,28,22),bodyMat);torso.scale.set(1,.95,.72);torso.position.y=.9;group.add(torso);
      const belly=new THREE.Mesh(new THREE.SphereGeometry(.34,24,18),mat(0xf0d5b2,.42,.02));belly.scale.set(1,.9,.28);belly.position.set(0,.79,.39);group.add(belly);
      for(const x of [-.39,.39]){const ear=new THREE.Mesh(new THREE.SphereGeometry(.2,20,16),bodyMat);ear.position.set(x,1.39,.02);group.add(ear);const inner=new THREE.Mesh(new THREE.SphereGeometry(.105,16,12),mat(0xf3b5a4,.4,.02));inner.position.set(x,1.4,.17);group.add(inner)}
      addEyes(group,[[-.2,1.08,.48,1],[.2,1.08,.48,1]],eyeMat,darkMat);
      const nose=new THREE.Mesh(new THREE.SphereGeometry(.075,16,12),darkMat);nose.position.set(0,.91,.53);group.add(nose);
      for(const side of [-1,1]){const arm=new THREE.Mesh(new THREE.SphereGeometry(.19,18,14),bodyMat);arm.scale.set(.78,1.45,.8);arm.position.set(side*.62,.82,0);group.add(arm);const foot=new THREE.Mesh(new THREE.SphereGeometry(.22,18,14),darkMat);foot.scale.set(1,.58,1);foot.position.set(side*.29,.28,.12);group.add(foot)}
      const scarf=roundedBlock(.72,.12,.18,.045,mat(0x67e8d9,.28,.18));scarf.position.set(0,.54,.42);group.add(scarf);
    }else if(id==='prism'){
      const crystalMat=new THREE.MeshPhysicalMaterial({color:0x57cfff,roughness:.16,metalness:.2,transmission:.12,thickness:.7,clearcoat:1,clearcoatRoughness:.1,emissive:0x064e83,emissiveIntensity:.55,flatShading:true});
      const crystal=new THREE.Mesh(new THREE.OctahedronGeometry(.78,0),crystalMat);crystal.position.y=1.02;crystal.scale.set(.83,1.1,.68);crystal.rotation.y=.22;group.add(crystal);
      const inner=new THREE.Mesh(new THREE.OctahedronGeometry(.43,0),mat(0xd6fbff,.16,.32,0x3a9fff));inner.position.set(0,1.03,.19);inner.scale.set(.8,1.05,.6);group.add(inner);
      const band=new THREE.Mesh(new THREE.TorusGeometry(.57,.055,10,48),goldMat);band.position.y=.95;band.rotation.x=Math.PI/2;group.add(band);
      addEyes(group,[[-.16,1.16,.47,.72],[.16,1.16,.47,.72]],eyeMat,darkMat);
      const shard1=new THREE.Mesh(new THREE.OctahedronGeometry(.2),mat(0xa2f4ff,.18,.3,0x278aff));shard1.position.set(-.8,1.05,0);shard1.rotation.z=.4;group.add(shard1);
      const shard2=shard1.clone();shard2.position.set(.78,.74,.02);shard2.rotation.z=-.5;group.add(shard2);
    }else if(id==='blip'){
      const head=new THREE.Mesh(new THREE.SphereGeometry(.64,24,20),mat(0x8c61d9,.27,.14,0x48218b));head.scale.set(1.08,.88,.8);head.position.y=1.02;group.add(head);
      const jaw=new THREE.Mesh(new THREE.SphereGeometry(.35,20,16),mat(0x5c399d,.32,.08));jaw.scale.set(1,.48,.65);jaw.position.set(0,.63,.2);group.add(jaw);
      addEyes(group,[[-.24,1.12,.48,1.25],[.24,1.12,.48,1.25]],eyeMat,mat(0x31145c,.2,.08));
      for(const side of [-1,1]){const horn=new THREE.Mesh(new THREE.ConeGeometry(.13,.42,7),mat(0xd4a9ff,.25,.12,0x6a2bb5));horn.position.set(side*.42,1.65,0);horn.rotation.z=-side*.35;group.add(horn);const arm=new THREE.Mesh(new THREE.CapsuleGeometry(.12,.36,4,8),mat(0x6d45b2,.3,.12));arm.position.set(side*.66,.76,0);arm.rotation.z=-side*.55;group.add(arm)}
      const antenna=new THREE.Mesh(new THREE.CylinderGeometry(.025,.04,.28,8),metalMat);antenna.position.set(0,1.65,0);group.add(antenna);
      const orb=new THREE.Mesh(new THREE.SphereGeometry(.105,16,12),mat(0x69fff1,.15,.2,0x44fff0));orb.position.set(0,1.82,0);group.add(orb);
      const mouth=new THREE.Mesh(new THREE.TorusGeometry(.11,.025,6,20,Math.PI),darkMat);mouth.position.set(0,.78,.49);mouth.rotation.z=Math.PI;group.add(mouth);
    }else if(id==='pixel'){
      const torso=roundedBlock(.95,.88,.64,.13,mat(0x4bdaa7,.25,.46,0x087d60));torso.position.y=.87;group.add(torso);
      const face=roundedBlock(.68,.42,.075,.07,mat(0x172b42,.18,.25));face.position.set(0,1.05,.36);group.add(face);
      for(const x of [-.19,.19]){const eye=new THREE.Mesh(new THREE.BoxGeometry(.12,.15,.04),mat(x<0?0x5bfff0:0xb2ff76,.18,.2,0x41ffe0));eye.position.set(x,1.08,.415);group.add(eye)}
      const antenna=new THREE.Mesh(new THREE.CylinderGeometry(.035,.05,.28,8),metalMat);antenna.position.set(0,1.48,0);group.add(antenna);
      const antennaTip=new THREE.Mesh(new THREE.BoxGeometry(.17,.17,.17),goldMat);antennaTip.position.set(0,1.69,0);group.add(antennaTip);
      for(const side of [-1,1]){const shoulder=roundedBlock(.28,.31,.35,.06,metalMat);shoulder.position.set(side*.62,1.08,0);group.add(shoulder);const arm=roundedBlock(.18,.46,.2,.045,mat(0x279b83,.28,.5));arm.position.set(side*.64,.73,0);group.add(arm);const leg=roundedBlock(.25,.36,.3,.05,mat(0x263c5d,.3,.4));leg.position.set(side*.25,.25,0);group.add(leg);const foot=roundedBlock(.34,.16,.4,.04,darkMat);foot.position.set(side*.25,.12,.08);group.add(foot)}
      for(let i=0;i<3;i++){const vent=new THREE.Mesh(new THREE.BoxGeometry(.09,.045,.025),goldMat);vent.position.set(-.1+i*.1,.68,.335);group.add(vent)}
    }else if(id==='spark'){
      const coreMat=mat(0xffc247,.2,.3,0xff8a18);
      const core=new THREE.Mesh(new THREE.SphereGeometry(.48,24,20),coreMat);core.scale.set(.86,1.12,.72);core.position.y=1.02;group.add(core);
      const armor=new THREE.Mesh(new THREE.IcosahedronGeometry(.61,0),mat(0xffdf70,.22,.35,0xffa51e));armor.scale.set(.82,1.1,.62);armor.position.y=1.03;group.add(armor);
      addEyes(group,[[-.17,1.12,.43,.85],[.17,1.12,.43,.85]],eyeMat,darkMat);
      const boltShape=new THREE.Shape();boltShape.moveTo(.08,.42);boltShape.lineTo(-.13,.05);boltShape.lineTo(.02,.05);boltShape.lineTo(-.09,-.35);boltShape.lineTo(.2,.08);boltShape.lineTo(.05,.08);boltShape.closePath();
      const boltGeo=new THREE.ExtrudeGeometry(boltShape,{depth:.08,bevelEnabled:true,bevelSegments:2,bevelSize:.025,bevelThickness:.025});const bolt=new THREE.Mesh(boltGeo,mat(0xfff6b0,.18,.25,0xffd34e));bolt.position.set(.43,1.18,.05);bolt.rotation.z=-.12;group.add(bolt);
      for(const side of [-1,1]){const fin=new THREE.Mesh(new THREE.ConeGeometry(.15,.5,5),mat(0xff8a2a,.22,.2,0xff5a16));fin.position.set(side*.47,1.47,-.05);fin.rotation.z=-side*.85;group.add(fin)}
      const baseRing=new THREE.Mesh(new THREE.TorusGeometry(.53,.07,8,36),goldMat);baseRing.position.y=.35;baseRing.rotation.x=Math.PI/2;group.add(baseRing);
    }
    // Character-specific surface details to push each silhouette beyond a simple primitive.
    if(id==='plush'){
      // Guardian shoulder plates and small rivets frame the worn-fabric body.
      for(const side of [-1,1]){
        const plate=new THREE.Mesh(new THREE.SphereGeometry(.22,16,12),mat(0x43506e,.3,.68,0x15264b));
        plate.scale.set(1.12,.62,.48);plate.position.set(side*.53,1.12,.13);plate.rotation.z=-side*.32;group.add(plate);
        for(let i=0;i<3;i++){const stitch=new THREE.Mesh(new THREE.SphereGeometry(.018,8,6),goldMat);stitch.position.set(side*.53+side*(i-1)*.07,1.13,.245);group.add(stitch)}
      }
      const chestBadge=new THREE.Mesh(new THREE.OctahedronGeometry(.12,0),goldMat);chestBadge.position.set(0,.93,.55);chestBadge.rotation.z=Math.PI/4;group.add(chestBadge);
    }else if(id==='prism'){
      // Three orbiting crystal fragments form a magical, layered silhouette.
      const orbit=new THREE.Group();orbit.position.set(0,1.02,0);group.add(orbit);
      for(let i=0;i<3;i++){const shard=new THREE.Mesh(new THREE.OctahedronGeometry(.105+i*.025,0),mat([0x7af4ff,0xb7a5ff,0xffffff][i],.14,.25,0x2d78ff));const a=i*Math.PI*2/3;shard.position.set(Math.cos(a)*.92,Math.sin(a)*.34,Math.sin(a)*.42);shard.rotation.set(a*.4,a,a*.7);orbit.add(shard)}
      orbit.userData.bbOrbit=true;
    }else if(id==='blip'){
      const cheekMat=mat(0xc7a4ff,.34,.04,0x30105b);
      for(const side of [-1,1]){const cheek=new THREE.Mesh(new THREE.SphereGeometry(.095,12,8),cheekMat);cheek.scale.set(1,.55,.28);cheek.position.set(side*.39,.91,.44);group.add(cheek)}
      const tooth=new THREE.Mesh(new THREE.BoxGeometry(.12,.055,.035),mat(0xffffff,.2,.02));tooth.position.set(.04,.78,.51);group.add(tooth);
    }else if(id==='pixel'){
      const panel=roundedBlock(.42,.14,.035,.025,mat(0x1c2d4b,.24,.52));panel.position.set(0,.48,.34);group.add(panel);
      for(let i=0;i<4;i++){const diode=new THREE.Mesh(new THREE.SphereGeometry(.025,8,6),new THREE.MeshBasicMaterial({color:[0x65fff0,0xffd36e,0xa98aff,0x7dff9b][i]}));diode.position.set(-.12+i*.08,.48,.37);group.add(diode)}
      const shoulderMark=new THREE.Mesh(new THREE.BoxGeometry(.16,.07,.035),goldMat);shoulderMark.position.set(.45,1.19,.19);shoulderMark.rotation.z=-.35;group.add(shoulderMark);
    }else if(id==='spark'){
      // Fine lightning filaments sit just outside the core as a readable energy motif.
      for(let i=0;i<4;i++){
        const points=[];const a=i*Math.PI/2+.2;
        points.push(new THREE.Vector3(Math.cos(a)*.42,.78,Math.sin(a)*.3));
        points.push(new THREE.Vector3(Math.cos(a+.12)*.68,1.02,Math.sin(a+.12)*.45));
        points.push(new THREE.Vector3(Math.cos(a-.08)*.54,1.28,Math.sin(a-.08)*.38));
        const filament=new THREE.Line(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineBasicMaterial({color:0xfff0a2,transparent:true,opacity:.9}));group.add(filament);
      }
    }
    const halo=new THREE.Mesh(new THREE.TorusGeometry(id==='prism'?.78:.72,.025,8,64),new THREE.MeshBasicMaterial({color:base,transparent:true,opacity:.72}));halo.rotation.x=Math.PI/2;halo.position.y=.12;group.add(halo);
    const ring2=new THREE.Mesh(new THREE.TorusGeometry(id==='pixel'?.88:.9,.009,6,64),new THREE.MeshBasicMaterial({color:0x9baeff,transparent:true,opacity:.42}));ring2.rotation.x=Math.PI/2;ring2.position.y=.08;group.add(ring2);
    for(let i=0;i<18;i++){const a=i*2.399,rad=.92+(i%3)*.14;const p=new THREE.Mesh(new THREE.OctahedronGeometry(i%4===0?.045:.022),glowMat);p.position.set(Math.cos(a)*rad,.35+(i%5)*.27,Math.sin(a)*rad*.55);sparkles.add(p)}
    group.add(sparkles);group.scale.setScalar(id==='blip'?.95:id==='pixel'?.92:1.02);
    return {group,halo,ring2,sparkles};
  }
  function mount(stage){
    if(stage.dataset.bb3dReady==='1')return;
    stage.dataset.bb3dReady='1';
    const fallback=document.createElement('div');fallback.className='bb-3d-fallback';fallback.textContent=stage.dataset.heroEmoji||'🧸';stage.appendChild(fallback);
    try{
      const scene=new THREE.Scene();const camera=new THREE.PerspectiveCamera(34,1,.1,100);camera.position.set(0,1.5,5.8);camera.lookAt(0,.9,0);
      const renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,powerPreference:'high-performance',stencil:false,depth:true});
      renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,2));renderer.setSize(stage.clientWidth||320,stage.clientHeight||260,false);
      renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.22;
      renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
      renderer.domElement.setAttribute('aria-label','Объёмная 3D-модель персонажа');renderer.domElement.setAttribute('role','img');stage.insertBefore(renderer.domElement,fallback);fallback.style.display='none';
      scene.add(new THREE.HemisphereLight(0xc6d8ff,0x1a1c42,2.0));
      const key=new THREE.DirectionalLight(0xfff4df,4.0);key.position.set(3,5,4);key.castShadow=true;key.shadow.mapSize.set(1024,1024);scene.add(key);
      const fill=new THREE.DirectionalLight(0x7b8cff,2.2);fill.position.set(-4,2,-3);scene.add(fill);
      const rim=new THREE.PointLight(colorFor(stage.dataset.heroId),24,9);rim.position.set(-2,2,2);scene.add(rim);
      const accent=new THREE.PointLight(0x8c5bff,10,7);accent.position.set(2,.8,-2);scene.add(accent);
      // A miniature holographic showcase stage: layered metallic plinth, emissive rings,
      // a deep starfield and floating architectural arcs instead of a flat preview card.
      const base=colorFor(stage.dataset.heroId),stageRig=new THREE.Group();scene.add(stageRig);
      const plinthMat=new THREE.MeshStandardMaterial({color:0x121a35,metalness:.82,roughness:.24});
      const plinth=new THREE.Mesh(new THREE.CylinderGeometry(.94,1.04,.12,64),plinthMat);plinth.position.y=.015;plinth.receiveShadow=true;stageRig.add(plinth);
      const top=new THREE.Mesh(new THREE.CylinderGeometry(.88,.94,.035,64),new THREE.MeshStandardMaterial({color:0x20294b,metalness:.72,roughness:.2,emissive:base,emissiveIntensity:.08}));top.position.y=.09;stageRig.add(top);
      const edge=new THREE.Mesh(new THREE.TorusGeometry(.94,.025,10,72),new THREE.MeshBasicMaterial({color:base}));edge.rotation.x=Math.PI/2;edge.position.y=.075;stageRig.add(edge);
      const innerEdge=new THREE.Mesh(new THREE.TorusGeometry(.69,.009,8,72),new THREE.MeshBasicMaterial({color:0x9e8bff,transparent:true,opacity:.85}));innerEdge.rotation.x=Math.PI/2;innerEdge.position.y=.112;stageRig.add(innerEdge);
      const floor=new THREE.Mesh(new THREE.CircleGeometry(1.5,64),new THREE.MeshBasicMaterial({color:base,transparent:true,opacity:.12,side:THREE.DoubleSide}));floor.rotation.x=-Math.PI/2;floor.position.y=.105;stageRig.add(floor);
      const arcMat=new THREE.MeshBasicMaterial({color:base,transparent:true,opacity:.34});
      for(let i=0;i<3;i++){const arc=new THREE.Mesh(new THREE.TorusGeometry(1.35+i*.22,.008,6,72,Math.PI*1.15),arcMat);arc.position.set(0,.82-i*.13,-.55);arc.rotation.set(.45+i*.24,.25+i*.5,.35+i*.4);stageRig.add(arc)}
      const stars=new THREE.BufferGeometry(),starPositions=[];
      for(let i=0;i<180;i++){starPositions.push((Math.random()-.5)*7,Math.random()*4.5-.1,-2.5-Math.random()*3)}
      stars.setAttribute('position',new THREE.Float32BufferAttribute(starPositions,3));
      const starField=new THREE.Points(stars,new THREE.PointsMaterial({color:0xc5d9ff,size:.018,transparent:true,opacity:.78,sizeAttenuation:true}));scene.add(starField);
      const char=makeCharacter(stage);char.group.position.y=.12;scene.add(char.group);
      const caption=document.createElement('div');caption.className='bb-3d-caption';caption.textContent='TETRIOS.LX · 3D CHARACTER SHOWCASE';stage.appendChild(caption);
      const resize=()=>{if(!stage.isConnected)return;const w=Math.max(1,stage.clientWidth),h=Math.max(1,stage.clientHeight);renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix()};
      const ro=new ResizeObserver(resize);ro.observe(stage);
      // Touch/mouse drag lets players inspect the mascot instead of seeing a fixed thumbnail.
      let dragging=false,lastX=0,lastY=0;const controls={targetY:0,targetX:0};
      const down=e=>{dragging=true;lastX=e.clientX;lastY=e.clientY;stage.classList.add('bb-3d-dragging');if(renderer.domElement.setPointerCapture&&e.pointerId!==undefined){try{renderer.domElement.setPointerCapture(e.pointerId)}catch(_){}}};
      const move=e=>{if(!dragging)return;controls.targetY+=(e.clientX-lastX)*.012;controls.targetX=Math.max(-.28,Math.min(.28,controls.targetX+(e.clientY-lastY)*.006));lastX=e.clientX;lastY=e.clientY};
      const up=()=>{dragging=false;stage.classList.remove('bb-3d-dragging')};
      renderer.domElement.style.touchAction='pan-y';
      renderer.domElement.addEventListener('pointerdown',down);
      renderer.domElement.addEventListener('pointermove',move);
      renderer.domElement.addEventListener('pointerup',up);
      renderer.domElement.addEventListener('pointercancel',up);
      renderer.domElement.addEventListener('lostpointercapture',up);
      stage.addEventListener('pointerleave',up);
      active.set(stage,{renderer,scene,camera,char,ro,controls,cleanup:()=>{renderer.domElement.removeEventListener('pointerdown',down);renderer.domElement.removeEventListener('pointermove',move);renderer.domElement.removeEventListener('pointerup',up);renderer.domElement.removeEventListener('pointercancel',up);renderer.domElement.removeEventListener('lostpointercapture',up);stage.removeEventListener('pointerleave',up)}});
    }catch(err){console.warn('[Tetrios 3D] Renderer failed; keeping fallback artwork.',err);fallback.style.display='';}
  }
  function scan(){document.querySelectorAll('.bb-3d-stage').forEach(mount);for(const [stage,item] of active){if(!stage.isConnected){item.ro.disconnect();item.cleanup?.();item.renderer.dispose();active.delete(stage)}}}
  const clock=new THREE.Clock();
  function frame(){requestAnimationFrame(frame);const t=clock.getElapsedTime();scan();for(const [stage,item] of active){if(stage.offsetParent===null)continue;item.char.group.position.y=.12+Math.sin(t*1.8)*.065;item.char.group.rotation.y+=(item.controls.targetY+Math.sin(t*.55)*.2-item.char.group.rotation.y)*.08;item.char.group.rotation.x+=(item.controls.targetX-item.char.group.rotation.x)*.08;item.char.halo.rotation.z=t*.38;item.char.ring2.rotation.z=-t*.22;item.char.sparkles.rotation.y=t*.28;for(const part of item.char.group.children){if(part.userData.bbOrbit)part.rotation.y=t*.9}item.renderer.render(item.scene,item.camera)}}
  new MutationObserver(scan).observe(document.body,{childList:true,subtree:true});scan();frame();
})();