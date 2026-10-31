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
  try{THREE=await import('./vendor/three/build/three.module.js')}
  catch(error){toggle.title='Для 3D-режима требуется загрузка Three.js';toggle.addEventListener('click',()=>{toggle.textContent='3D НЕДОСТУПНО';setTimeout(()=>toggle.textContent='3D ARENA',1800)});return}
  let renderer,scene,camera,boardGroup,activeGroup,ghostGroup,gridGroup,effectsGroup,resizeObserver,pulseGroups=[],enabled=false,resumeAfterContextRestore=false,lastBoardSignature='',lastPieceSignature='',raf=0,previousState=null,lastSyncAt=0,lastFrameAt=0,pieceOffsetX=0,pieceOffsetY=0,rotationAngle=0,rotationPivotX=0,rotationPivotY=0,lastClearAt=0,clearStreak=0,impactAt=0,impactStrength=0;
  const reducedMotion=window.matchMedia('(prefers-reduced-motion: reduce)');
  const lowPowerDevice=(navigator.hardwareConcurrency&&navigator.hardwareConcurrency<=4)||(navigator.deviceMemory&&navigator.deviceMemory<=4);
  const colorCache=new Map(),coreCache=new Map(),edgeCache=new Map(),geometryCache=new Map(),sharedMaterials=new Set(),sharedGeometries=new Set();
  const geometryFor=(key,create)=>{if(!geometryCache.has(key)){const geometry=create();geometryCache.set(key,geometry);sharedGeometries.add(geometry)}return geometryCache.get(key)};
  const materialFor=(color,ghost=false)=>{
    const key=String(color)+':'+ghost;
    if(!colorCache.has(key)){
      const options={
        color,roughness:ghost?.52:.2,metalness:ghost?.08:.62,
        emissive:color,emissiveIntensity:ghost?.08:.28,
        transparent:ghost,opacity:ghost?.18:1
      };
      const material=lowPowerDevice
        ?new THREE.MeshStandardMaterial(options)
        :new THREE.MeshPhysicalMaterial({...options,clearcoat:ghost?0:.9,clearcoatRoughness:.12});
      colorCache.set(key,material);sharedMaterials.add(material);
    }
    return colorCache.get(key);
  };
  const coreMaterialFor=color=>{
    const key=String(color);
    if(!coreCache.has(key)){const material=new THREE.MeshBasicMaterial({color,transparent:true,opacity:.72,depthWrite:false});coreCache.set(key,material);sharedMaterials.add(material);}
    return coreCache.get(key);
  };
  const edgeMaterialFor=color=>{
    const key=String(color);
    if(!edgeCache.has(key)){const material=new THREE.MeshStandardMaterial({color,metalness:.9,roughness:.16,emissive:color,emissiveIntensity:.5});edgeCache.set(key,material);sharedMaterials.add(material);}
    return edgeCache.get(key);
  };
  function init(){
    if(renderer)return;
    scene=new THREE.Scene();scene.background=null;
    camera=new THREE.OrthographicCamera(-5.5,5.5,11,-11,.1,100);
    camera.position.set(0,0,34);camera.lookAt(0,0,0);
    renderer=new THREE.WebGLRenderer({alpha:true,antialias:!lowPowerDevice,powerPreference:lowPowerDevice?'low-power':'high-performance'});
    // Keep the arena crisp on desktop while avoiding a costly high-DPI framebuffer on phones/tablets.
    const pixelCap=lowPowerDevice?1:1.35;
    renderer.setPixelRatio(Math.min(window.devicePixelRatio||1,pixelCap));
    renderer.outputColorSpace=THREE.SRGBColorSpace;
    renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;
    renderer.domElement.className='bb-arena-canvas';renderer.domElement.setAttribute('aria-hidden','true');
    renderer.domElement.addEventListener('webglcontextlost',event=>{
      event.preventDefault();
      if(raf){cancelAnimationFrame(raf);raf=0;}
      resumeAfterContextRestore=enabled;
      enabled=false;frame.classList.remove('bb-3d-arena-active');toggle.setAttribute('aria-pressed','false');
      // A lost WebGL canvas must never remain above the working 2D board.
      renderer.domElement.style.display='none';
      renderer.domElement.style.visibility='hidden';
      renderer.domElement.style.opacity='0';
      toggle.textContent='3D ВОССТАНАВЛИВАЕТСЯ';toggle.title='3D-графика временно недоступна; игра продолжает работать в 2D';
      console.warn('[Tetrios 3D arena] WebGL context lost; continuing in 2D.');
    });
    renderer.domElement.addEventListener('webglcontextrestored',()=>{
      toggle.textContent='3D ARENA';toggle.title='Переключить объёмное игровое поле';
      if(resumeAfterContextRestore){
        // Three.js restores its WebGL state; rebuild dynamic groups from the authoritative game state.
        resumeAfterContextRestore=false;
        lastBoardSignature='';lastPieceSignature='';previousState=null;
        setEnabled(true);
      }
    });
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
    pulseGroups=[boardGroup,activeGroup,ghostGroup];
    effectsGroup=new THREE.Group();scene.add(effectsGroup);
    const resize=()=>{if(!renderer)return;const frameRect=frame.getBoundingClientRect(),boardRect=boardCanvas.getBoundingClientRect();const w=Math.max(1,boardRect.width),h=Math.max(1,boardRect.height),aspect=w/h;renderer.domElement.style.left=(boardRect.left-frameRect.left-frame.clientLeft)+'px';renderer.domElement.style.top=(boardRect.top-frameRect.top-frame.clientTop)+'px';renderer.domElement.style.width=w+'px';renderer.domElement.style.height=h+'px';const arenaWidth=10.9,arenaHeight=21.2,viewHeight=Math.max(arenaHeight,arenaWidth/aspect)*1.025,viewWidth=viewHeight*aspect;renderer.setSize(w,h,false);camera.left=-viewWidth/2;camera.right=viewWidth/2;camera.top=viewHeight/2;camera.bottom=-viewHeight/2;camera.updateProjectionMatrix()};
    resizeObserver=new ResizeObserver(resize);resizeObserver.observe(frame);resizeObserver.observe(boardCanvas);window.addEventListener('resize',resize,{passive:true});resize();
  }
  function blockInto(target,x,y,color,ghost=false){
    const cell=new THREE.Group();
    cell.position.set(x-4.5,9.5-y,ghost?.03:.24);
    cell.userData.pulsePhase=(x*7+y*13)%19;
    const geo=geometryFor('block',()=>{
      const shape=new THREE.Shape(),size=.78,r=.095,x=-size/2,y=-size/2;
      shape.moveTo(x+r,y);shape.lineTo(x+size-r,y);shape.quadraticCurveTo(x+size,y,x+size,y+r);
      shape.lineTo(x+size,y+size-r);shape.quadraticCurveTo(x+size,y+size,x+size-r,y+size);
      shape.lineTo(x+r,y+size);shape.quadraticCurveTo(x,y+size,x,y+size-r);
      shape.lineTo(x,y+r);shape.quadraticCurveTo(x,y,x+r,y);
      const bevel=lowPowerDevice?2:4;
      const geometry=new THREE.ExtrudeGeometry(shape,{
        depth:.51,bevelEnabled:true,bevelSegments:bevel,steps:1,
        bevelSize:.055,bevelThickness:.055,curveSegments:lowPowerDevice?3:6
      });
      geometry.translate(0,0,-.255);
      return geometry;
    });
    const mesh=new THREE.Mesh(geo,materialFor(color,ghost));
    cell.add(mesh);
    const edges=new THREE.LineSegments(geometryFor('block-edges',()=>new THREE.EdgesGeometry(geo)),new THREE.LineBasicMaterial({color:ghost?0x91eaff:0xe6ffff,transparent:true,opacity:ghost?.28:.78}));
    edges.position.z=.002;cell.add(edges);
    if(!ghost){
      // A recessed-looking luminous core and machined metal rails give each block its own material identity.
      const core=new THREE.Mesh(geometryFor('block-core',()=>new THREE.BoxGeometry(.43,.43,.025)),coreMaterialFor(color));
      core.position.set(.035,-.015,.323);cell.add(core);
      const frameMat=edgeMaterialFor(color);
      const topRail=new THREE.Mesh(geometryFor('block-top-rail',()=>new THREE.BoxGeometry(.62,.035,.035)),frameMat);
      topRail.position.set(0,.365,.29);cell.add(topRail);
      const sideRail=new THREE.Mesh(geometryFor('block-side-rail',()=>new THREE.BoxGeometry(.035,.56,.035)),frameMat);
      sideRail.position.set(.365,-.015,.29);cell.add(sideRail);
      const shine=new THREE.Mesh(geometryFor('block-shine',()=>new THREE.BoxGeometry(.52,.025,.018)),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.72}));
      shine.position.set(-.025,.285,.338);cell.add(shine);
      const accent=new THREE.Mesh(geometryFor('block-accent',()=>new THREE.BoxGeometry(.035,.42,.025)),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.35}));
      accent.position.set(-.345,-.045,.326);cell.add(accent);
      const corner=new THREE.Mesh(geometryFor('block-corner',()=>new THREE.BoxGeometry(.12,.035,.025)),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.62}));
      corner.position.set(.275,-.345,.326);cell.add(corner);
    }
    target.add(cell);
  }
  const MAX_ARENA_EFFECTS=96;
  function disposeEffect(effect){
    if(effect.geometry)effect.geometry.dispose();
    if(effect.material){
      const list=Array.isArray(effect.material)?effect.material:[effect.material];
      list.forEach(material=>material.dispose());
    }
  }
  function addEffect(effect){
    effectsGroup.add(effect);
    while(effectsGroup.children.length>MAX_ARENA_EFFECTS){
      const oldest=effectsGroup.children[0];
      effectsGroup.remove(oldest);
      disposeEffect(oldest);
    }
  }
  function disposeGroup(group){
    group.traverse(obj=>{
      if(obj.geometry&&!sharedGeometries.has(obj.geometry))obj.geometry.dispose();
      if(obj.material){
        const list=Array.isArray(obj.material)?obj.material:[obj.material];
        for(const m of list)if(!sharedMaterials.has(m))m.dispose();
      }
    });
    group.clear();
  }
  function rotateMatrix(matrix,direction){
    const height=matrix.length,width=matrix[0]?.length||0;
    if(!height||!width)return [];
    const rotated=Array.from({length:width},()=>Array(height).fill(0));
    for(let y=0;y<height;y++)for(let x=0;x<width;x++){
      if(direction>0)rotated[x][height-1-y]=matrix[y][x];
      else rotated[width-1-x][y]=matrix[y][x];
    }
    return rotated;
  }
  function sameMatrix(a,b){
    return a.length===b.length&&a.every((row,y)=>row.length===b[y]?.length&&row.every((value,x)=>value===b[y][x]));
  }
  function sync(){
    if(!enabled||!window.bbGet3DBoardState)return;
    const state=window.bbGet3DBoardState();
    if(previousState&&Number.isFinite(state.lines)&&Number.isFinite(previousState.lines)&&state.lines>previousState.lines){
      const now=performance.now(),count=Math.min(4,state.lines-previousState.lines);
      clearStreak=now-lastClearAt<1800?Math.min(5,clearStreak+1):1;lastClearAt=now;
      // A compact camera impulse makes a line clear register without shaking the UI.
      impactAt=now;impactStrength=Math.min(.24,.09+count*.035);
      for(let i=effectsGroup.children.length-1;i>=0;i--){
        const obj=effectsGroup.children[i];effectsGroup.remove(obj);
        disposeEffect(obj);
      }
      for(let n=0;n<count;n++){
        const mat=new THREE.MeshBasicMaterial({color:n%2?0xa98aff:0x9ffff8,transparent:true,opacity:.98,side:THREE.DoubleSide});
        const flash=new THREE.Mesh(new THREE.PlaneGeometry(10,.72),mat);
        flash.position.set(0,-9.15+n*.72,.48);flash.userData.createdAt=now;flash.userData.life=460+clearStreak*90;flash.userData.clearFlash=true;
        addEffect(flash);
      }
      // A short radial burst makes consecutive clears feel stronger without changing scoring.
      const particleCount=reducedMotion.matches?0:Math.min(lowPowerDevice?20:36,12+count*4+clearStreak*3);
      for(let i=0;i<particleCount;i++){
        const angle=(Math.PI*2*i/particleCount)+(Math.random()-.5)*.12;
        const speed=.035+Math.random()*.055;
        const mat=new THREE.MeshBasicMaterial({color:i%3===0?0xffd47a:(i%2?0xa98aff:0x75fff0),transparent:true,opacity:.95});
        const particle=new THREE.Mesh(new THREE.SphereGeometry(.035+Math.random()*.035,6,5),mat);
        particle.position.set(Math.cos(angle)*2.8,(Math.random()-.5)*13,.55);
        particle.userData.createdAt=now;particle.userData.life=520+clearStreak*110;
        particle.userData.velocity={x:Math.cos(angle)*speed,y:Math.sin(angle)*speed};
        addEffect(particle);
      }
    }
    const boardSignature=JSON.stringify([state.board,state.colors]);
    const boardChanged=boardSignature!==lastBoardSignature;
    const linesChanged=!!previousState&&Number.isFinite(state.lines)&&Number.isFinite(previousState.lines)&&state.lines>previousState.lines;
    // A locked piece becomes part of the settled board. Brief cell flashes make that transition readable.
    if(boardChanged&&previousState?.piece&&!linesChanged){
      const oldPiece=previousState.piece,now=performance.now();
      const dropDistance=Math.max(0,(Number.isFinite(previousState.ghostY)?previousState.ghostY:oldPiece.y)-oldPiece.y);
      impactAt=now;impactStrength=Math.min(.32,.08+dropDistance*.025);
      oldPiece.shape.forEach((row,dy)=>row.forEach((v,dx)=>{
        if(!v||oldPiece.y+dy<0)return;
        const mat=new THREE.MeshBasicMaterial({color:0x8ffff7,transparent:true,opacity:.82,side:THREE.DoubleSide});
        const flash=new THREE.Mesh(new THREE.PlaneGeometry(.82,.82),mat);
        flash.position.set(oldPiece.x+dx-4.5,9.5-(oldPiece.y+dy),.52);
        flash.userData.createdAt=now;flash.userData.life=360;
        addEffect(flash);
      }));
      // Ground shockwave: a quick horizontal energy sweep under the locked piece.
      const shockMat=new THREE.MeshBasicMaterial({color:0x75fff0,transparent:true,opacity:.9,side:THREE.DoubleSide});
      const shock=new THREE.Mesh(new THREE.PlaneGeometry(8.8,.055),shockMat);
      shock.position.set(0,Math.max(-9.72,Math.min(9.6,9.5-oldPiece.y)),.5);
      shock.userData.createdAt=now;shock.userData.life=300;shock.userData.shockwave=true;
      addEffect(shock);
    }
    const landingKeys=new Set();
    const landedPiece=boardChanged&&previousState?.piece&&!linesChanged?previousState.piece:null;
    if(landedPiece)landedPiece.shape.forEach((row,dy)=>row.forEach((v,dx)=>{
      if(v&&landedPiece.y+dy>=0)landingKeys.add((landedPiece.x+dx)+','+(landedPiece.y+dy));
    }));
    if(boardChanged){
      lastBoardSignature=boardSignature;
      disposeGroup(boardGroup);
      const colors=state.colors||[];
      for(let y=0;y<state.height;y++)for(let x=0;x<state.width;x++){
        const v=state.board[y]?.[x];
        if(v){
          blockInto(boardGroup,x,y,colors[v-1]||'#69f4ff');
          const cell=boardGroup.children[boardGroup.children.length-1];
          if(!reducedMotion.matches&&landingKeys.has(x+','+y)){
            cell.userData.landAt=performance.now();
            cell.scale.set(1,.78,1);
          }
        }
      }
    }
    const pieceSignature=JSON.stringify([state.piece,state.ghostY,state.colors]);
    if(pieceSignature!==lastPieceSignature){
      lastPieceSignature=pieceSignature;
      const oldPiece=previousState?.piece,newPiece=state.piece;
      const samePieceType=!!(oldPiece&&newPiece&&oldPiece.t===newPiece.t);
      const sameFallingPiece=samePieceType&&sameMatrix(oldPiece.shape,newPiece.shape);
      // Rebuild at the authoritative logical state. If the matrix rotated, begin at the
      // inverse visual angle and ease to the new orientation around the piece centre.
      pieceOffsetX=!reducedMotion.matches&&sameFallingPiece?oldPiece.x-newPiece.x:0;
      const fallDistance=sameFallingPiece?newPiece.y-oldPiece.y:0;
      pieceOffsetY=!reducedMotion.matches&&fallDistance>0?Math.min(fallDistance,2.5):0;
      rotationAngle=0;rotationPivotX=0;rotationPivotY=0;
      if(!reducedMotion.matches&&samePieceType&&!sameFallingPiece){
        const oldShape=oldPiece.shape,newShape=newPiece.shape;
        const direction=sameMatrix(rotateMatrix(oldShape,1),newShape)?1:
          (sameMatrix(rotateMatrix(oldShape,-1),newShape)?-1:0);
        if(direction){
          rotationAngle=-direction*Math.PI/2;
          const height=newShape.length,width=newShape[0]?.length||0;
          rotationPivotX=newPiece.x+width/2-4.5;
          rotationPivotY=9.5-(newPiece.y+height/2);
          // A compact rotating arc marks the input response without obscuring the tetromino.
          const rotationAt=performance.now();
          const arcMaterial=new THREE.MeshBasicMaterial({color:0x9ffff8,transparent:true,opacity:.92,depthWrite:false,side:THREE.DoubleSide});
          const rotationArc=new THREE.Mesh(new THREE.TorusGeometry(.78,.035,5,18,Math.PI*1.55),arcMaterial);
          rotationArc.position.set(rotationPivotX,rotationPivotY,.58);
          rotationArc.rotation.z=direction>0?-.35:Math.PI-.35;
          rotationArc.userData.createdAt=rotationAt;
          rotationArc.userData.life=310;
          rotationArc.userData.rotationArc=true;
          addEffect(rotationArc);
        }
      }
      disposeGroup(activeGroup);disposeGroup(ghostGroup);
      const colors=state.colors||[];
      if(newPiece){
        const p=newPiece,color=colors[p.t]||'#69f4ff';
        if(Number.isFinite(state.ghostY))p.shape.forEach((row,dy)=>row.forEach((v,dx)=>{if(v&&state.ghostY+dy>=0)blockInto(ghostGroup,p.x+dx,state.ghostY+dy,color,true)}));
        p.shape.forEach((row,dy)=>row.forEach((v,dx)=>{if(v&&p.y+dy>=0)blockInto(activeGroup,p.x+dx,p.y+dy,color)}));
      }
      activeGroup.rotation.z=rotationAngle;
      activeGroup.position.set(pieceOffsetX+rotationPivotX*(1-Math.cos(rotationAngle))+rotationPivotY*Math.sin(rotationAngle),pieceOffsetY+rotationPivotY*(1-Math.cos(rotationAngle))-rotationPivotX*Math.sin(rotationAngle),0);
    }
    previousState={...state,board:state.board?.map(row=>row.slice())};
  }
  function animate(){
    raf=0;
    if(!enabled||!renderer||document.hidden)return;
    const now=performance.now();
    const deltaSeconds=lastFrameAt?Math.min(.05,Math.max(.004,(now-lastFrameAt)/1000)):1/60;
    const deltaScale=deltaSeconds/(1/60);
    lastFrameAt=now;
    // The board changes only on input/tick events; syncing at ~25 Hz keeps the 60 Hz render loop light.
    if(now-lastSyncAt>=40){sync();lastSyncAt=now;}
    if(effectsGroup){
      for(let i=effectsGroup.children.length-1;i>=0;i--){
        const effect=effectsGroup.children[i];
        const age=now-(effect.userData.createdAt||now),life=effect.userData.life||460;
        const progress=Math.min(1,age/life);
        // Reduced-motion mode keeps the visual cue static and short-lived instead of animating it.
        effect.material.opacity=reducedMotion.matches?.78:(1-progress)*.95;
        if(!reducedMotion.matches){
          if(effect.userData.velocity){
            effect.position.x+=effect.userData.velocity.x*deltaScale;
            effect.position.y+=effect.userData.velocity.y*deltaScale;
            effect.scale.setScalar(1-progress*.7);
          }else if(effect.userData.rotationArc){
            effect.rotation.z+=.045*deltaScale;
            effect.scale.setScalar(1+progress*.38);
          }else if(effect.userData.shockwave){
            effect.scale.x=1+progress*.08;effect.scale.y=1+progress*3.5;
          }else{
            effect.scale.set(1+progress*.16,1+progress*.22,1);
          }
        }
        if(progress>=1){effectsGroup.remove(effect);disposeEffect(effect);}
      }
    }
    if(!reducedMotion.matches){
      const t=now*.00025,impactAge=now-impactAt;
      const shake=impactAt&&impactAge<240?Math.sin(impactAge*.085)*impactStrength*(1-impactAge/240):0;
      camera.position.x=shake;
      camera.position.y=0;
      for(let g=0;g<pulseGroups.length;g++){
        const cells=pulseGroups[g].children;
        for(let i=0;i<cells.length;i++){
          const cell=cells[i];
          if(cell.isGroup){
            const pulse=1+Math.sin(now*.004+cell.userData.pulsePhase)*.008;
            if(cell.userData.landAt){
              const progress=Math.min(1,(now-cell.userData.landAt)/260);
              const rebound=1-.22*Math.exp(-progress*7)*Math.cos(progress*12);
              cell.scale.set(pulse,pulse*rebound,1);
              if(progress>=1)delete cell.userData.landAt;
            }else cell.scale.set(pulse,pulse,1);
          }
        }
      }
      if(pieceOffsetX||pieceOffsetY||Math.abs(rotationAngle)>.002){
        const ease=Math.exp(-deltaSeconds*24);
        pieceOffsetX*=ease;pieceOffsetY*=ease;rotationAngle*=ease;
        if(Math.abs(pieceOffsetX)<.015)pieceOffsetX=0;
        if(Math.abs(pieceOffsetY)<.015)pieceOffsetY=0;
        if(Math.abs(rotationAngle)<.002)rotationAngle=0;
        activeGroup.rotation.z=rotationAngle;
        const c=Math.cos(rotationAngle),sn=Math.sin(rotationAngle);
        activeGroup.position.set(
          pieceOffsetX+rotationPivotX*(1-c)+rotationPivotY*sn,
          pieceOffsetY+rotationPivotY*(1-c)-rotationPivotX*sn,0
        );
      }
    }
    camera.lookAt(0,0,0);renderer.render(scene,camera);
    raf=requestAnimationFrame(animate);
  }
  function setEnabled(next){
    enabled=!!next;
    toggle.setAttribute('aria-pressed',String(enabled));
    toggle.textContent=enabled?'2D РЕЖИМ':'3D ARENA';
    frame.classList.toggle('bb-3d-arena-active',enabled);
    // Do not rely on stylesheet state alone: explicitly remove the WebGL canvas from
    // layout/paint while 2D is active so a stale framebuffer can never cover the game.
    if(renderer?.domElement){
      renderer.domElement.style.display=enabled?'block':'none';
      renderer.domElement.style.visibility=enabled?'visible':'hidden';
      renderer.domElement.style.opacity=enabled?'1':'0';
    }
    if(!enabled&&raf){cancelAnimationFrame(raf);raf=0;}
    if(enabled){
      try{
        init();
        if(renderer?.domElement){
          renderer.domElement.style.display='block';
          renderer.domElement.style.visibility='visible';
          renderer.domElement.style.opacity='1';
        }
        sync();lastSyncAt=performance.now();
        if(!raf){lastFrameAt=0;animate()}
      }catch(error){
        enabled=false;frame.classList.remove('bb-3d-arena-active');
        toggle.setAttribute('aria-pressed','false');toggle.textContent='3D НЕДОСТУПНО';
        if(renderer?.domElement){
          renderer.domElement.style.display='none';
          renderer.domElement.style.visibility='hidden';
          renderer.domElement.style.opacity='0';
        }
        console.warn('[Tetrios 3D arena] WebGL unavailable; returning to 2D.',error);
        setTimeout(()=>{toggle.textContent='3D ARENA'},2200)
      }
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
  document.addEventListener('visibilitychange',()=>{if(document.hidden&&raf){cancelAnimationFrame(raf);raf=0;}else if(!document.hidden&&enabled){sync();lastSyncAt=performance.now();if(!raf){lastFrameAt=0;animate();}}});
})();