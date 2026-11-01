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

  function createProceduralModel(id,index){
    const group=new THREE.Group();
    const palettes={
      planet:0x3c9cbd,'earth-moon':0x3f9db9,'lava-world':0xd85b24,neptune:0x3159c8,
      mars:0xb85d3d,uranus:0x71c9c9,saturn:0xd7b36d,'black-hole':0x28203f,
      mercury:0x9a8b82,'solar-system':0xf4b94e,'spiral-galaxy':0x9874dc,sun:0xffb83e
    };
    const color=palettes[id]||0x6d8fd8;
    const segments=lowPower?20:32;
    const bodyMaterial=new THREE.MeshStandardMaterial({color,roughness:id==='sun'||id==='black-hole'?.38:.72,metalness:.12,emissive:id==='sun'||id==='lava-world'?color:0x000000,emissiveIntensity:id==='sun'?.42:id==='lava-world'?.18:0});
    const sphere=(radius,mat,x=0,y=0,z=0)=>{
      const mesh=new THREE.Mesh(new THREE.SphereGeometry(radius,segments,Math.max(12,Math.floor(segments*.7))),mat);
      mesh.position.set(x,y,z);group.add(mesh);return mesh;
    };
    const ring=(radius,tube,mat,rotation=0)=>{
      const mesh=new THREE.Mesh(new THREE.TorusGeometry(radius,tube,8,lowPower?36:64),mat);
      mesh.rotation.x=Math.PI/2+rotation;group.add(mesh);return mesh;
    };
    if(id==='black-hole'){
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
      if(id==='sun'){
        ring(.96,.018,new THREE.MeshBasicMaterial({color:0xffd77a,transparent:true,opacity:.75}),.4);
      }
      if(id==='lava-world'){
        ring(.91,.035,new THREE.MeshBasicMaterial({color:0xff6a26,emissive:0xff3b12}),.2);
      }
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
    // Inline fixed positioning prevents later campaign styles from demoting the WebGL layer.
    Object.assign(canvas.style,{
      position:'fixed',left:'0px',top:'0px',width:'1px',height:'1px',
      zIndex:'9999',display:'block',pointerEvents:'none',
      background:'transparent',maxWidth:'none',maxHeight:'none'
    });
    document.body.appendChild(canvas);
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
      visibleSlots.add(slot);

      // Draw a local 3D model immediately; never leave the animated 2D icon underneath it.
      try{
        const immediate=buildScene(createProceduralModel(id,index),index);
        entries.set(slot,immediate);
        slot.classList.add('is-loaded','is-model-fallback');
        slot.closest('.bb-planet-node')?.classList.add('is-3d');
        requestRender();
      }catch(error){
        console.warn(log,'immediate procedural model failed for '+id+'.',error);
      }

      // Upgrade the visible local model to the detailed GLB when the remote asset arrives.
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
      // Keep the body-level fixed canvas aligned to the active viewport.
      const vr=viewport.getBoundingClientRect();
      canvas.style.left=vr.left+'px';
      canvas.style.top=vr.top+'px';
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
      // Reposition the fixed overlay to the active viewport's live screen coordinates.
      canvas.style.left=vr.left+'px';
      canvas.style.top=vr.top+'px';
      const cw=viewport.clientWidth,ch=viewport.clientHeight;
      renderer.setScissorTest(false);renderer.clear(true,true,true);renderer.setScissorTest(true);
      entries.forEach((entry,slot)=>{
        const rect=slot.getBoundingClientRect();
        if(rect.right<vr.left||rect.left>vr.right||rect.bottom<vr.top||rect.top>vr.bottom)return;
        const x=Math.max(0,rect.left-vr.left);
        const y=Math.max(0,rect.top-vr.top);
        const w=Math.min(cw-x,rect.width),h=Math.min(ch-y,rect.height);
        if(w<2||h<2)return;
        entry.camera.aspect=w/h;entry.camera.updateProjectionMatrix();
        if(!reduceMotion.matches){
          entry.pivot.rotation.y+=dt*.18;
          entry.pivot.rotation.x=Math.sin(now*.00035+entry.index)*.035;
          entry.pivot.position.y=Math.sin(now*.0008+entry.index)*.025;
        }
        renderer.setViewport(x,ch-y-h,w,h);
        renderer.setScissor(x,ch-y-h,w,h);
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
