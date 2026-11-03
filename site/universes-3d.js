/* Tetrios.LX — lazy-loaded 3D universe models for the campaign galaxy atlas.
   One shared WebGL renderer draws only the visible GLB models, keeping mobile GPU use low. */
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

(async function(){
  const log='[Tetrios 3D Universes]';
  const reduceMotion=window.matchMedia('(prefers-reduced-motion: reduce)');
  let manifest;
  try{
    const response=await fetch('./universes/manifest.json',{cache:'force-cache'});
    if(!response.ok)throw new Error('manifest HTTP '+response.status);
    manifest=await response.json();
  }catch(error){console.warn(log,'manifest unavailable; emoji fallback stays active.',error);return;}

  const loader=new GLTFLoader();
  let active=null,raf=0,last=0;
  const modelCache=new Map();
  const visibleSlots=new Set();
  const isIOS=/iPad|iPhone|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);
  const lowPower=isIOS||(navigator.hardwareConcurrency||8)<=4||(navigator.deviceMemory||8)<=4;

  function loadModel(id){
    if(modelCache.has(id))return modelCache.get(id);
    const entry=manifest.models[id];
    if(!entry)return Promise.reject(new Error('Unknown model '+id));
    const promise=loader.loadAsync(entry.url).then(gltf=>gltf.scene).catch(error=>{
      modelCache.delete(id);
      throw error;
    });
    modelCache.set(id,promise);
    return promise;
  }

  function createProceduralModel(id,index,variant=0){
    const group=new THREE.Group();
    const palettes={
      planet:0x3c9cbd,'earth-moon':0x3f9db9,'lava-world':0xd85b24,neptune:0x3159c8,
      mars:0xb85d3d,uranus:0x71c9c9,saturn:0xd7b36d,'black-hole':0x28203f,
      mercury:0x9a8b82,'solar-system':0xf4b94e,'spiral-galaxy':0x9874dc,sun:0xffb83e,
      'cargo-spaceship':0x9bbad1,'cargo-shuttle':0xe6c47c,'escape-pod':0xf0a45e,
      'space-fighter':0xe77d79,'sci-fi-spaceship':0x8ac9e5,'moon-base-dome':0x93cbd0,
      'drone-bot':0x9d8bd9,'mech-walker':0x83b9a4,'portal-gate':0xa98bff,
      'antenna-array':0x9bb8d0,'alien-egg':0xc29be8,'alien-plant':0x79c8a5
    };
    const color=palettes[id]||0x6d8fd8;
    const segments=lowPower?20:32;
    const bodyMaterial=new THREE.MeshStandardMaterial({
      color,roughness:id==='sun'||id==='black-hole'||id==='portal-gate'?.38:.72,
      metalness:.12,emissive:id==='sun'||id==='lava-world'||id==='portal-gate'?color:0x000000,
      emissiveIntensity:id==='sun'?.42:id==='lava-world'?.18:id==='portal-gate'?.2:0
    });
    const accent=new THREE.MeshStandardMaterial({color:0x65e9ed,metalness:.3,roughness:.28,emissive:0x1b9ba9,emissiveIntensity:.42});
    const pale=new THREE.MeshStandardMaterial({color:0xe5edf2,metalness:.22,roughness:.48});
    const dark=new THREE.MeshStandardMaterial({color:0x18253b,metalness:.45,roughness:.38});
    const sphere=(radius,mat,x=0,y=0,z=0)=>{
      const mesh=new THREE.Mesh(new THREE.SphereGeometry(radius,segments,Math.max(12,Math.floor(segments*.7))),mat);
      mesh.position.set(x,y,z);group.add(mesh);return mesh;
    };
    const ring=(radius,tube,mat,rotation=0)=>{
      const mesh=new THREE.Mesh(new THREE.TorusGeometry(radius,tube,8,lowPower?36:64),mat);
      mesh.rotation.x=Math.PI/2+rotation;group.add(mesh);return mesh;
    };
    const box=(w,h,d,mat,x=0,y=0,z=0)=>{
      const mesh=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),mat);
      mesh.position.set(x,y,z);group.add(mesh);return mesh;
    };
    const cylinder=(rt,rb,height,mat,x=0,y=0,z=0,rotateX=0)=>{
      const mesh=new THREE.Mesh(new THREE.CylinderGeometry(rt,rb,height,lowPower?10:16),mat);
      mesh.position.set(x,y,z);mesh.rotation.x=rotateX;group.add(mesh);return mesh;
    };
    if(id==='planet'&&variant>0){
      // Each of the 360 campaign nodes receives a deterministic, non-repeating world.
      // The atlas nodes use procedural variants so a shared base GLB never repeats.
      const seed=variant*9301+49297;
      const random=(n)=>{const x=Math.sin(seed+n*127.1)*43758.5453;return x-Math.floor(x);};
      const palettes=[0x3c9cbd,0x6c8bd8,0xb56b56,0x79a98c,0xb99a62,0x806bb8,0x4e9b9a,0xc47d92,0x7c8c9d,0x9c754f,0x5d77a8,0x8aaf6c];
      const color=new THREE.Color(palettes[Math.floor(random(1)*palettes.length)]);
      const surface=new THREE.MeshStandardMaterial({color,roughness:.84,metalness:.04});
      const land=new THREE.MeshStandardMaterial({color:new THREE.Color().setHSL((variant*.071)%1,.42,.58),roughness:.9});
      const glow=new THREE.MeshBasicMaterial({color:new THREE.Color().setHSL((variant*.113)%1,.78,.68),transparent:true,opacity:.2,side:THREE.BackSide});
      const shape=variant%7;
      const core=sphere(.68,surface);
      // Give campaign worlds visibly different silhouettes, not just different colors.
      const shapeScale=[
        [1,1,1], [1.28,.72,.94], [.82,1.3,.88], [1.38,.86,.78],
        [.9,1.18,.94], [1.08,.88,1.2], [.96,1.04,.9]
      ][shape];
      core.scale.set(...shapeScale);
      if(shape===6){core.geometry.dispose();core.geometry=new THREE.IcosahedronGeometry(.68,1);}
      if(shape===5){
        sphere(.28,surface,.43,.08,.12).scale.set(1,.78,.9);
        sphere(.2,surface,-.36,-.22,.24).scale.set(.92,1.12,.82);
      }
      const atmosphere=new THREE.Mesh(new THREE.SphereGeometry(.73,segments,Math.max(12,Math.floor(segments*.7))),glow);
      atmosphere.scale.set(...shapeScale.map(value=>value*1.055));
      group.add(atmosphere);
      const landCount=3+Math.floor(random(2)*6);
      for(let i=0;i<landCount;i++){
        const lat=(random(i+3)-.5)*Math.PI*.82,lon=random(i+13)*Math.PI*2;
        const patch=sphere(.11+random(i+23)*.14,land,Math.cos(lat)*Math.cos(lon)*.61,Math.sin(lat)*.61,Math.cos(lat)*Math.sin(lon)*.61);
        patch.scale.set(1.35,.42,.86);
        patch.lookAt(0,0,0);
      }
      if(random(31)>.28){
        const ringMat=new THREE.MeshStandardMaterial({color:new THREE.Color().setHSL((variant*.037+.12)%1,.48,.72),metalness:.35,roughness:.42,transparent:true,opacity:.82});
        const ringMesh=ring(.82,.035+random(32)*.035,ringMat,(random(33)-.5)*.9);
        ringMesh.scale.set(1,1+random(34)*.35,1);
      }
      const moonCount=Math.floor(random(35)*3);
      for(let i=0;i<moonCount;i++){
        const angle=random(i+40)*Math.PI*2,orbit=.96+random(i+50)*.38;
        sphere(.055+random(i+60)*.045,new THREE.MeshStandardMaterial({color:0xcbd5e1,roughness:.9}),Math.cos(angle)*orbit,Math.sin(angle)*.3,Math.sin(angle)*orbit);
      }
      const craterCount=2+Math.floor(random(70)*5);
      for(let i=0;i<craterCount;i++){
        const angle=random(i+80)*Math.PI*2,dist=.42+random(i+90)*.18;
        const crater=sphere(.045+random(i+100)*.035,dark,Math.cos(angle)*dist,Math.sin(i*2.1)*.26,Math.sin(angle)*dist);
        crater.scale.set(1,.55,1);
      }
    }else if(id==='black-hole'){
      sphere(.62,new THREE.MeshBasicMaterial({color:0x03030b}));
      ring(.83,.12,new THREE.MeshStandardMaterial({color:0x9b5cff,emissive:0x713bff,emissiveIntensity:2,metalness:.35,roughness:.24}),.22);
      ring(1.02,.035,new THREE.MeshBasicMaterial({color:0xffbd72}),-.12);
    }else if(id==='spiral-galaxy'){
      sphere(.18,new THREE.MeshBasicMaterial({color:0xffe2a0}));
      for(let arm=0;arm<3;arm++){
        const points=[];
        for(let i=0;i<48;i++){const t=i/47*Math.PI*2.2+arm*Math.PI*2/3,r=.12+i/47*.92;points.push(new THREE.Vector3(Math.cos(t)*r,Math.sin(t)*r*.32,Math.sin(t)*r*.18));}
        const curve=new THREE.CatmullRomCurve3(points);
        const mesh=new THREE.Mesh(new THREE.TubeGeometry(curve,64,.035,5,false),new THREE.MeshBasicMaterial({color:[0x9c7cff,0x65dfff,0xffcf82][arm]}));group.add(mesh);
      }
    }else if(id==='solar-system'){
      sphere(.28,new THREE.MeshBasicMaterial({color:0xffc45f}));
      [0.48,.72,.98,1.22].forEach((r,i)=>{
        ring(r,.009,new THREE.MeshBasicMaterial({color:0x8db9ff,transparent:true,opacity:.4}),.02*i);
        sphere(.065+i*.012,new THREE.MeshStandardMaterial({color:[0x62c9ee,0xd8a26c,0x6d87d9,0x75cba8][i]}),Math.cos(i*1.5)*r,Math.sin(i*1.5)*r*.22,Math.sin(i*1.5)*r);
      });
    }else if(id==='cargo-spaceship'||id==='cargo-shuttle'||id==='space-fighter'||id==='sci-fi-spaceship'){
      const fighter=id==='space-fighter',shuttle=id==='cargo-shuttle';
      box(.34,.22,1.25,bodyMaterial,0,0,0);
      const nose=new THREE.Mesh(new THREE.ConeGeometry(fighter?.2:.25,.48,8),pale);
      nose.rotation.x=Math.PI/2;nose.position.z=.82;group.add(nose);
      box(fighter?1.45:1.05,.07,.52,pale,0,-.01,.08);
      box(.13,.28,.36,bodyMaterial,0,.13,-.48);
      box(.26,.08,.25,dark,0,.15,.2);
      for(const side of [-1,1]){
        cylinder(.095,.095,.48,accent,side*.28,0,-.5,Math.PI/2);
        sphere(.11,accent,side*.28,0,-.76);
      }
      if(id==='cargo-spaceship'||shuttle){
        for(let i=0;i<(shuttle?4:6);i++){
          const x=(i%2?1:-1)*.22,y=.17,z=(shuttle?-.22:-.42)+Math.floor(i/2)*.28;
          box(.28,.2,.23,[pale,new THREE.MeshStandardMaterial({color:0xe7b978}),new THREE.MeshStandardMaterial({color:0x82cbd1})][i%3],x,y,z);
        }
        if(shuttle)box(.55,.08,.34,dark,0,-.16,-.82);
      }
    }else if(id==='escape-pod'){
      const pod=sphere(.68,bodyMaterial);pod.scale.set(.78,1,.8);
      ring(.62,.07,pale,.05);
      sphere(.24,dark,0,.08,.48);
      sphere(.14,accent,0,.08,.59);
      for(let i=0;i<4;i++){const a=i*Math.PI/2;box(.12,.32,.12,pale,Math.cos(a)*.55,-.48,Math.sin(a)*.55);}
    }else if(id==='asteroid'){
      const rock=new THREE.Mesh(new THREE.DodecahedronGeometry(.8,1),bodyMaterial);
      rock.scale.set(1.15,.82,.9);rock.rotation.set(.35,.55,.2);group.add(rock);
      for(let i=0;i<5;i++){
        const a=i*2.4,r=.48+(i%2)*.12;
        sphere(.12,dark,Math.cos(a)*r,Math.sin(a)*r*.7,.45*Math.sin(a*.7));
      }
    }else if(id==='moon-base-dome'){
      cylinder(.78,.82,.18,dark,0,-.56,0);
      const dome=new THREE.Mesh(new THREE.SphereGeometry(.67,24,12,0,Math.PI*2,0,Math.PI/2),pale);
      dome.position.y=-.46;group.add(dome);
      for(let i=0;i<6;i++){const a=i*Math.PI/3;box(.035,.78,.035,accent,Math.cos(a)*.58,-.2,Math.sin(a)*.58);}
      box(.32,.24,.34,bodyMaterial,0,-.48,.7);
      cylinder(.035,.045,.75,accent,.65,.04,-.2);
    }else if(id==='drone-bot'){
      sphere(.58,pale,0,.05,0);
      ring(.72,.07,accent,.18);
      sphere(.25,dark,0,.06,.48);
      sphere(.16,accent,0,.06,.62);
      for(const side of [-1,1]){box(.24,.08,.16,bodyMaterial,side*.64,-.05,0);cylinder(.04,.04,.35,pale,side*.72,-.28,0);}
    }else if(id==='mech-walker'){
      box(.65,.55,.38,bodyMaterial,0,.12,0);
      sphere(.32,pale,0,.58,.06);
      sphere(.12,accent,0,.58,.38);
      for(const side of [-1,1]){
        cylinder(.13,.17,.55,dark,side*.25,-.43,0);
        box(.24,.12,.34,pale,side*.25,-.77,.1);
        box(.32,.12,.22,bodyMaterial,side*.52,.18,0);
      }
    }else if(id==='portal-gate'){
      const gate=new THREE.Mesh(new THREE.TorusGeometry(.72,.1,12,48),pale);
      group.add(gate);
      const glow=new THREE.Mesh(new THREE.CircleGeometry(.62,40),new THREE.MeshBasicMaterial({color:0x8d6cff,transparent:true,opacity:.48,side:THREE.DoubleSide}));
      glow.position.z=-.035;group.add(glow);
      const swirl=new THREE.Mesh(new THREE.TorusGeometry(.36,.035,8,36),accent);swirl.rotation.z=.7;swirl.position.z=.03;group.add(swirl);
      box(.18,.85,.2,dark,-.76,-.35,0);box(.18,.85,.2,dark,.76,-.35,0);box(1.9,.14,.48,pale,0,-.88,0);
    }else if(id==='antenna-array'){
      cylinder(.52,.62,.16,dark,0,-.65,0);
      cylinder(.045,.055,1.2,pale,0,-.02,0);
      const dish=new THREE.Mesh(new THREE.SphereGeometry(.42,20,12,0,Math.PI*2,0,Math.PI/2),pale);
      dish.rotation.x=Math.PI/2;dish.position.set(0,.42,.12);group.add(dish);
      sphere(.08,accent,0,.44,.38);
      box(.38,.24,.28,bodyMaterial,.48,-.48,0);
    }else if(id==='alien-egg'){
      const egg=sphere(.62,bodyMaterial);egg.scale.set(.78,1.12,.68);egg.rotation.z=-.18;
      ring(.52,.045,accent,-.3);
      for(let i=0;i<4;i++){const leaf=sphere(.22,new THREE.MeshStandardMaterial({color:[0x8dd7b4,0x71bfa6,0x9b8be0,0x68d5d2][i]}),Math.cos(i*Math.PI/2)*.62,-.35,Math.sin(i*Math.PI/2)*.5);leaf.scale.set(.65,1.7,.4);leaf.rotation.z=(i-1.5)*.32;}
    }else if(id==='alien-plant'){
      cylinder(.34,.4,.28,pale,0,-.68,0);
      cylinder(.055,.075,.75,new THREE.MeshStandardMaterial({color:0x5c9e7c}),0,-.18,0);
      for(let i=0;i<5;i++){
        const a=i*Math.PI*2/5,x=Math.cos(a)*.48,y=.12+(i%2)*.14,z=Math.sin(a)*.28;
        const leaf=sphere(.2,new THREE.MeshStandardMaterial({color:0x6fc59b}),x,y,z);leaf.scale.set(.55,1.6,.42);leaf.rotation.z=-a;
        sphere(.12,accent,x*1.25,.55+(i%2)*.12,z*1.2);
      }
    }else{
      sphere(.78,bodyMaterial);
      if(id==='earth-moon'){
        sphere(.18,new THREE.MeshStandardMaterial({color:0xb8b9c2,roughness:.9}),1.02,.45,0);
        ring(1.02,.009,new THREE.MeshBasicMaterial({color:0xb8d8ff,transparent:true,opacity:.45}),.18);
      }
      if(id==='saturn'||id==='uranus'){
        ring(1.02,.12,new THREE.MeshStandardMaterial({color:id==='saturn'?0xd8bd85:0x9be2e2,metalness:.35,roughness:.55,side:THREE.DoubleSide}),id==='uranus'?.72:.12);
        ring(1.17,.025,new THREE.MeshBasicMaterial({color:id==='saturn'?0xf4dfb0:0x74d2e0,transparent:true,opacity:.72}),id==='uranus'?.72:.12);
      }
      if(id==='sun')ring(.96,.018,new THREE.MeshBasicMaterial({color:0xffd77a,transparent:true,opacity:.75}),.4);
      if(id==='lava-world')ring(.91,.035,new THREE.MeshBasicMaterial({color:0xff6a26,emissive:0xff3b12}),.2);
    }
    return group;
  }

  function buildScene(model,index){
    const scene=new THREE.Scene();
    scene.add(new THREE.HemisphereLight(0xdceaff,0x18213a,2.0));
    const key=new THREE.DirectionalLight(0xffffff,2.4);key.position.set(-3,5,6);scene.add(key);
    const fill=new THREE.DirectionalLight(0x83cfff,1.2);fill.position.set(4,1,-4);scene.add(fill);
    const rim=new THREE.PointLight(0x8c78ff,1.1,8);rim.position.set(0,1.5,-2);scene.add(rim);

    const pivot=new THREE.Group();
    const root=model;
    root.updateMatrixWorld(true);
    const bounds=new THREE.Box3().setFromObject(root);
    const size=bounds.getSize(new THREE.Vector3());
    const center=bounds.getCenter(new THREE.Vector3());
    const maxDim=Math.max(size.x,size.y,size.z)||1;
    const scale=1.72/maxDim;
    root.scale.setScalar(scale);
    root.position.sub(center.multiplyScalar(scale));
    pivot.add(root);
    pivot.rotation.y=(index%4)*.35;
    scene.add(pivot);

    const camera=new THREE.PerspectiveCamera(34,1,.1,40);
    camera.position.set(0,.08,3.35);
    camera.lookAt(0,0,0);
    return {scene,camera,pivot,index};
  }

  function disposeScene(scene){
    scene?.traverse(object=>{
      object.geometry?.dispose?.();
      const materials=Array.isArray(object.material)?object.material:[object.material];
      materials.filter(Boolean).forEach(material=>{
        Object.values(material).forEach(value=>{if(value?.isTexture)value.dispose()});
        material.dispose?.();
      });
    });
  }

  function stopCurrent(){
    if(!active)return;
    cancelAnimationFrame(raf);raf=0;
    active.observer?.disconnect();
    active.resizeObserver?.disconnect();
    if(active.resizeHandler)window.removeEventListener('resize',active.resizeHandler);
    if(active.scrollHandler)active.viewport.removeEventListener('scroll',active.scrollHandler);
    active.entries.forEach(entry=>disposeScene(entry.scene));
    active.entries.clear();
    modelCache.clear();
    visibleSlots.clear();
    active.renderer?.dispose();
    active.renderer?.forceContextLoss?.();
    active.canvas?.remove();
    active=null;
  }

  function startAtlas(viewport){
    if(active?.viewport===viewport)return;
    stopCurrent();
    const grid=viewport.closest('#mapgrid');
    if(!grid)return;
    const canvas=document.createElement('canvas');
    canvas.className='bb-galaxy-model-canvas';
    canvas.setAttribute('aria-hidden','true');
    // Keep WebGL inside the active map viewport, between its atmosphere and DOM labels.
    Object.assign(canvas.style,{
      position:'absolute',left:'0px',top:'0px',width:'1px',height:'1px',
      zIndex:'1',display:'block',pointerEvents:'none',
      background:'transparent',maxWidth:'none',maxHeight:'none'
    });
    viewport.appendChild(canvas);
    let renderer;
    try{
      renderer=new THREE.WebGLRenderer({canvas,alpha:true,antialias:!lowPower,powerPreference:'low-power'});
    }catch(error){
      canvas.remove();console.warn(log,'WebGL unavailable; using galaxy artwork fallback.',error);return;
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,lowPower?1:1.25));
    renderer.setClearColor(0x000000,0);
    renderer.outputColorSpace=THREE.SRGBColorSpace;
    renderer.toneMapping=THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure=1.12;
    renderer.setScissorTest(true);

    const slots=[...viewport.querySelectorAll('[data-universe-model]')];
    const entries=new Map();
    grid.style.position='relative';
    const state={viewport,grid,canvas,renderer,observer:null,resizeObserver:null,resizeHandler:null,scrollHandler:null,entries,slots};
    active=state;

    const activate=slot=>{
      if(entries.has(slot))return;
      const id=slot.dataset.universeModel;
      const index=Math.max(0,manifest.universeOrder.indexOf(id));
      const variant=Math.max(0,Number(slot.dataset.universeVariant)||0);
      visibleSlots.add(slot);

      // Campaign planet nodes use deterministic unique procedural worlds, not a repeated GLB.
      try{
        const immediate=buildScene(createProceduralModel(id,index,variant),index);
        entries.set(slot,immediate);
        slot.classList.add('is-loaded','is-model-fallback');
        slot.closest('.bb-planet-node')?.classList.add('is-3d');
        requestRender();
      }catch(error){
        console.warn(log,'immediate procedural model failed for '+id+'.',error);
      }
      if(variant)return;

      // Upgrade ordinary universe showcase slots to their detailed GLB model.
      loadModel(id).then(source=>{
        if(active!==state||!slot.isConnected||!visibleSlots.has(slot))return;
        const previous=entries.get(slot);
        if(previous)disposeScene(previous.scene);
        const upgraded=buildScene(source.clone(true),index);
        entries.set(slot,upgraded);
        slot.classList.add('is-loaded');
        slot.closest('.bb-planet-node')?.classList.add('is-3d');
        requestRender();
      }).catch(error=>{
        if(active!==state||!slot.isConnected||!visibleSlots.has(slot))return;
        // Keep the already visible procedural 3D model; remote GLB failure is non-fatal.
        console.warn(log,'GLB unavailable for '+id+'; keeping immediate local 3D model.',error);
      });
    };

    // Activate currently visible slots synchronously, before the first observer callback.
    const initialRect=viewport.getBoundingClientRect();
    slots.forEach(slot=>{
      const rect=slot.getBoundingClientRect();
      if(rect.right>initialRect.left&&rect.left<initialRect.right&&rect.bottom>initialRect.top&&rect.top<initialRect.bottom)activate(slot);
    });

    if('IntersectionObserver' in window){
      state.observer=new IntersectionObserver(items=>{
        items.forEach(item=>{
          if(item.isIntersecting)activate(item.target);
          else{
            const slot=item.target,id=slot.dataset.universeModel,entry=entries.get(slot);
            visibleSlots.delete(slot);
            if(entry){disposeScene(entry.scene);entries.delete(slot);modelCache.delete(id)}
          }
        });
      },{root:viewport,rootMargin:lowPower?'0px 90px 0px 90px':'0px 280px 0px 280px',threshold:0});
      slots.forEach(slot=>state.observer.observe(slot));
    }else slots.slice(0,3).forEach(activate);

    const resize=()=>{
      if(active!==state)return;
      const w=Math.max(1,viewport.clientWidth),h=Math.max(1,viewport.clientHeight);
      renderer.setSize(w,h,false);
      // The absolute canvas stays visually pinned to the viewport while its content scrolls.
      canvas.style.left=viewport.scrollLeft+'px';
      canvas.style.top=viewport.scrollTop+'px';
      canvas.style.width=w+'px';
      canvas.style.height=h+'px';
      requestRender();
    };
    state.resizeObserver=new ResizeObserver(resize);
    state.resizeObserver.observe(viewport);
    state.resizeHandler=resize;
    state.scrollHandler=requestRender;
    window.addEventListener('resize',resize,{passive:true});
    viewport.addEventListener('scroll',requestRender,{passive:true});
    resize();

    function draw(now){
      if(active!==state)return;
      const campaign=document.getElementById('campaign');
      if(document.hidden||campaign?.hidden){
        raf=requestAnimationFrame(draw);return;
      }
      const dt=Math.min(.05,(now-last)/1000||0);last=now;
      const vr=viewport.getBoundingClientRect();
      // Keep the in-viewport canvas aligned with the visible scrollport, not above the whole page.
      canvas.style.left=viewport.scrollLeft+'px';
      canvas.style.top=viewport.scrollTop+'px';
      const cw=viewport.clientWidth,ch=viewport.clientHeight;
      renderer.setScissorTest(false);renderer.clear(true,true,true);renderer.setScissorTest(true);
      entries.forEach((entry,slot)=>{
        const rect=slot.getBoundingClientRect();
        // Keep each model's full drawing viewport anchored to its real DOM slot.
        // Clip only the visible intersection with the horizontal map viewport.
        // Clamping the model origin before sizing used to stretch/re-centre cards
        // entering from the left edge, making models overlap their neighbours.
        const slotLeft=rect.left-vr.left;
        const slotTop=rect.top-vr.top;
        const slotRight=slotLeft+rect.width;
        const slotBottom=slotTop+rect.height;
        const clipLeft=Math.max(0,slotLeft);
        const clipTop=Math.max(0,slotTop);
        const clipRight=Math.min(cw,slotRight);
        const clipBottom=Math.min(ch,slotBottom);
        const clipWidth=clipRight-clipLeft;
        const clipHeight=clipBottom-clipTop;
        if(clipWidth<2||clipHeight<2||rect.width<2||rect.height<2)return;
        entry.camera.aspect=rect.width/rect.height;entry.camera.updateProjectionMatrix();
        if(!reduceMotion.matches){
          entry.pivot.rotation.y+=dt*.18;
          entry.pivot.rotation.x=Math.sin(now*.00035+entry.index)*.035;
          entry.pivot.position.y=Math.sin(now*.0008+entry.index)*.025;
        }
        // WebGL viewport may extend beyond the canvas; scissor performs the crop.
        // This preserves the model's original size and centre while scrolling.
        renderer.setViewport(slotLeft,ch-slotBottom,rect.width,rect.height);
        renderer.setScissor(clipLeft,ch-clipBottom,clipWidth,clipHeight);
        renderer.render(entry.scene,entry.camera);
      });
      raf=requestAnimationFrame(draw);
    }
    function requestRender(){if(active===state&&!raf){last=performance.now();raf=requestAnimationFrame(draw)}}
    requestRender();
  }

  function scan(){
    // The campaign reuses #mapgrid when moving between galaxy and planet maps.
    // Select the currently visible viewport and detect replaced model slots even
    // when the viewport element itself was kept in the DOM.
    const candidates=[...document.querySelectorAll('#campaign .bb-galaxy-viewport, #campaign .bb-planet-viewport')];
    const viewport=candidates.find(candidate=>{
      if(!candidate.isConnected||!candidate.querySelector('[data-universe-model]'))return false;
      if(candidate.closest('[hidden]'))return false;
      const style=getComputedStyle(candidate);
      const rect=candidate.getBoundingClientRect();
      return style.display!=='none'&&style.visibility!=='hidden'&&rect.width>0&&rect.height>0&&candidate.getClientRects().length>0;
    });
    if(!viewport){if(active)stopCurrent();return}
    const slots=[...viewport.querySelectorAll('[data-universe-model]')];
    const sameSlots=active?.viewport===viewport&&active.slots.length===slots.length&&active.slots.every((slot,index)=>slot===slots[index]&&slot.isConnected);
    if(!sameSlots){
      requestAnimationFrame(()=>{
        if(!viewport.isConnected||viewport.closest('[hidden]'))return;
        const rect=viewport.getBoundingClientRect();
        if(rect.width>0&&rect.height>0)startAtlas(viewport);
      });
    }
  }
  const observer=new MutationObserver(scan);
  observer.observe(document.body,{childList:true,subtree:true});
  window.addEventListener('pageshow',scan);
  document.addEventListener('visibilitychange',()=>{if(!document.hidden&&active)requestRender()});
  scan();
})();
