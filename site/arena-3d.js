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
  let THREE=null,threePromise=null;
  const ensureThree=async()=>{
    if(THREE)return THREE;
    if(!threePromise)threePromise=import('./vendor/three/build/three.module.js');
    THREE=await threePromise;return THREE;
  };
  let renderer,scene,camera,boardGroup,activeGroup,ghostGroup,gridGroup,effectsGroup,resizeObserver,pulseGroups=[],enabled=false,resumeAfterContextRestore=false,lastBoardSignature='',lastPieceSignature='',raf=0,previousState=null,lastSyncAt=0,lastFrameAt=0,pieceOffsetX=0,pieceOffsetY=0,rotationAngle=0,rotationPivotX=0,rotationPivotY=0,lastClearAt=0,clearStreak=0,impactAt=0,impactStrength=0,arenaPulseMaterial=null,arenaPulseAt=0,arenaPulseStrength=0;
  const reducedMotion=window.matchMedia('(prefers-reduced-motion: reduce)');
  const lowPowerDevice=(navigator.hardwareConcurrency&&navigator.hardwareConcurrency<=4)||(navigator.deviceMemory&&navigator.deviceMemory<=4);
  const colorCache=new Map(),coreCache=new Map(),edgeCache=new Map(),geometryCache=new Map(),sharedMaterials=new Set(),sharedGeometries=new Set();
  const geometryFor=(key,create)=>{if(!geometryCache.has(key)){const geometry=create();geometryCache.set(key,geometry);sharedGeometries.add(geometry)}return geometryCache.get(key)};
  const materialFor=(color,ghost=false)=>{
    const key=String(color)+':'+ghost;
    if(!colorCache.has(key)){
      const options={
        color,roughness:ghost?.52:.3,metalness:ghost?.08:.22,
        emissive:color,emissiveIntensity:ghost?.08:.12,
        transparent:ghost,opacity:ghost?.18:1
      };
      const material=lowPowerDevice
        ?new THREE.MeshStandardMaterial(options)
        :new THREE.MeshPhysicalMaterial({...options,clearcoat:ghost?0:.35,clearcoatRoughness:.2});
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
    // Open 3D playfield with the same dark base, alternating rows and readable grid as the 2D arena.
    const boardSurface=new THREE.Mesh(new THREE.PlaneGeometry(10,23),new THREE.MeshBasicMaterial({color:0x0a1222}));
    boardSurface.position.z=-.2;scene.add(boardSurface);
    const rowBandMaterial=new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.016,depthWrite:false});
    for(let y=1;y<23;y+=2){
      const band=new THREE.Mesh(new THREE.PlaneGeometry(10,.999),rowBandMaterial);
      band.position.set(0,11-y,-.17);scene.add(band);
    }
    const sideGlowMat=new THREE.MeshBasicMaterial({color:0x54fff0,transparent:true,opacity:.16});
    [-5.035,5.035].forEach(x=>{const glow=new THREE.Mesh(new THREE.BoxGeometry(.018,22.5,.025),sideGlowMat);glow.position.set(x,0,-.08);scene.add(glow)});
    gridGroup=new THREE.Group();scene.add(gridGroup);
    const lineMaterial=new THREE.LineBasicMaterial({color:0x38506f,transparent:true,opacity:.78});
    const positions=[];
    for(let x=0;x<=10;x++){const px=x-5;positions.push(px,-11.5,.01,px,11.5,.01)}
    for(let y=0;y<=23;y++){const py=11.5-y;positions.push(-5,py,.01,5,py,.01)}
    const gridGeo=new THREE.BufferGeometry();gridGeo.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));
    gridGroup.add(new THREE.LineSegments(gridGeo,lineMaterial));
    const majorPositions=[];
    for(let x=5;x<10;x+=5){const px=x-5;majorPositions.push(px,-11.5,.025,px,11.5,.025)}
    for(let y=5;y<23;y+=5){const py=11.5-y;majorPositions.push(-5,py,.025,5,py,.025)}
    const majorGeo=new THREE.BufferGeometry();majorGeo.setAttribute('position',new THREE.Float32BufferAttribute(majorPositions,3));
    gridGroup.add(new THREE.LineSegments(majorGeo,new THREE.LineBasicMaterial({color:0x75a6c9,transparent:true,opacity:.58})));
    const borderGeo=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-5,-11.5,.04),new THREE.Vector3(5,-11.5,.04),new THREE.Vector3(5,11.5,.04),new THREE.Vector3(-5,11.5,.04),new THREE.Vector3(-5,-11.5,.04)]);
    gridGroup.add(new THREE.Line(borderGeo,new THREE.LineBasicMaterial({color:0x7bd8e8,transparent:true,opacity:.9})));
    // A restrained cyan edge glow keeps the arena open instead of enclosing it in a box.
    const railMat=new THREE.MeshStandardMaterial({color:0x5df8ee,emissive:0x1a8e9c,emissiveIntensity:.8,metalness:.35,roughness:.3});
    arenaPulseMaterial=railMat;
    const railGeo=new THREE.BoxGeometry(.018,22.4,.03);
    [-5.18,5.18].forEach(x=>{const rail=new THREE.Mesh(railGeo,railMat);rail.position.set(x,0,-.04);gridGroup.add(rail)});
    boardGroup=new THREE.Group();scene.add(boardGroup);
    activeGroup=new THREE.Group();scene.add(activeGroup);
    ghostGroup=new THREE.Group();scene.add(ghostGroup);
    pulseGroups=[boardGroup,activeGroup,ghostGroup];
    effectsGroup=new THREE.Group();scene.add(effectsGroup);
    const resize=()=>{if(!renderer)return;const frameRect=frame.getBoundingClientRect(),boardRect=boardCanvas.getBoundingClientRect();const w=Math.max(1,boardRect.width),h=Math.max(1,boardRect.height),aspect=w/h;renderer.domElement.style.left=(boardRect.left-frameRect.left-frame.clientLeft)+'px';renderer.domElement.style.top=(boardRect.top-frameRect.top-frame.clientTop)+'px';renderer.domElement.style.width=w+'px';renderer.domElement.style.height=h+'px';const arenaWidth=10.12,arenaHeight=23.12,viewHeight=Math.max(arenaHeight,arenaWidth/aspect)*1.006,viewWidth=viewHeight*aspect;renderer.setSize(w,h,false);camera.left=-viewWidth/2;camera.right=viewWidth/2;camera.top=viewHeight/2;camera.bottom=-viewHeight/2;camera.updateProjectionMatrix()};
    resizeObserver=new ResizeObserver(resize);resizeObserver.observe(frame);resizeObserver.observe(boardCanvas);window.addEventListener('resize',resize,{passive:true});resize();
  }
  function blockInto(target,x,y,color,ghost=false){
    const cell=new THREE.Group();
    cell.position.set(x-4.5,11-y,ghost?.03:.24);
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
    const edges=new THREE.LineSegments(geometryFor('block-edges',()=>new THREE.EdgesGeometry(geo)),new THREE.LineBasicMaterial({color:ghost?0x91eaff:0xe6ffff,transparent:true,opacity:ghost?.22:.52}));
    edges.position.z=.002;cell.add(edges);
    if(!ghost){
      // Keep one soft top highlight, echoing the simple highlight used by 2D cells.
      const shine=new THREE.Mesh(geometryFor('block-shine',()=>new THREE.BoxGeometry(.52,.025,.018)),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.5}));
      shine.position.set(-.025,.285,.338);cell.add(shine);
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
      // The arena rails briefly answer a clear streak; no new meshes or render loop are created.
      arenaPulseAt=now;arenaPulseStrength=Math.min(.9,.28+count*.12+Math.max(0,clearStreak-1)*.08);
      for(let i=effectsGroup.children.length-1;i>=0;i--){
        const obj=effectsGroup.children[i];effectsGroup.remove(obj);
        disposeEffect(obj);
      }
      for(let n=0;n<count;n++){
        const mat=new THREE.MeshBasicMaterial({color:n%2?0xa98aff:0x9ffff8,transparent:true,opacity:.98,side:THREE.DoubleSide});
        const flash=new THREE.Mesh(new THREE.PlaneGeometry(10,.72),mat);
        flash.position.set(0,-10.65+n*.72,.48);flash.userData.createdAt=now;flash.userData.life=460+clearStreak*90;flash.userData.clearFlash=true;
        addEffect(flash);
      }
      // A short radial burst makes consecutive clears feel stronger without changing scoring.
      const particleCount=reducedMotion.matches?0:Math.min(lowPowerDevice?20:36,12+count*4+clearStreak*3);
      for(let i=0;i<particleCount;i++){
        const angle=(Math.PI*2*i/particleCount)+(Math.random()-.5)*.12;
        const speed=.035+Math.random()*.055;
        const mat=new THREE.MeshBasicMaterial({color:i%3===0?0xffd47a:(i%2?0xa98aff:0x75fff0),transparent:true,opacity:.95});
        const particle=new THREE.Mesh(new THREE.SphereGeometry(.035+Math.random()*.035,6,5),mat);
        particle.position.set(Math.cos(angle)*2.8,(Math.random()-.5)*15,.55);
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
        flash.position.set(oldPiece.x+dx-4.5,11-(oldPiece.y+dy),.52);
        flash.userData.createdAt=now;flash.userData.life=360;
        addEffect(flash);
      }));
      // Ground shockwave: a quick horizontal energy sweep under the locked piece.
      const shockMat=new THREE.MeshBasicMaterial({color:0x75fff0,transparent:true,opacity:.9,side:THREE.DoubleSide});
      const shock=new THREE.Mesh(new THREE.PlaneGeometry(8.8,.055),shockMat);
      shock.position.set(0,Math.max(-11.22,Math.min(11.22,11-oldPiece.y)),.5);
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
          rotationPivotY=11-(newPiece.y+height/2);
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
      const arenaPulseAge=now-arenaPulseAt,arenaPulseProgress=Math.min(1,arenaPulseAge/720);
      const arenaPulse=arenaPulseAt&&arenaPulseAge<720?Math.sin(arenaPulseProgress*Math.PI)*(1-arenaPulseProgress)*arenaPulseStrength:0;
      if(arenaPulseMaterial)arenaPulseMaterial.emissiveIntensity=1.6+arenaPulse;
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
  async function setEnabled(next){
    if(!next){
      enabled=false;
      toggle.setAttribute('aria-pressed','false');toggle.textContent='3D ARENA';
      frame.classList.remove('bb-3d-arena-active');frame.classList.add('bb-2d-arena-active');
      boardCanvas.style.display='block';boardCanvas.style.visibility='visible';boardCanvas.style.opacity='1';
      boardCanvas.style.width='auto';boardCanvas.style.height='100%';boardCanvas.style.maxWidth='100%';boardCanvas.style.maxHeight='100%';
      if(renderer?.domElement){renderer.domElement.style.display='none';renderer.domElement.style.visibility='hidden';renderer.domElement.style.opacity='0';}
      if(raf){cancelAnimationFrame(raf);raf=0;}
      return;
    }
    if(enabled)return;
    toggle.disabled=true;toggle.textContent='ЗАГРУЗКА 3D…';
    try{
      await ensureThree();
      enabled=true;
      init();
      toggle.setAttribute('aria-pressed','true');toggle.textContent='2D РЕЖИМ';
      frame.classList.add('bb-3d-arena-active');frame.classList.remove('bb-2d-arena-active');
      boardCanvas.style.display='block';boardCanvas.style.visibility='visible';boardCanvas.style.opacity='0';
      if(renderer?.domElement){renderer.domElement.style.display='block';renderer.domElement.style.visibility='visible';renderer.domElement.style.opacity='1';}
      sync();lastSyncAt=performance.now();
      if(!raf){lastFrameAt=0;animate();}
    }catch(error){
      enabled=false;frame.classList.remove('bb-3d-arena-active');frame.classList.add('bb-2d-arena-active');
      toggle.setAttribute('aria-pressed','false');toggle.textContent='3D НЕДОСТУПНО';
      if(renderer?.domElement){renderer.domElement.style.display='none';renderer.domElement.style.visibility='hidden';renderer.domElement.style.opacity='0';}
      console.warn('[Tetrios 3D arena] WebGL unavailable; returning to 2D.',error);
      setTimeout(()=>{toggle.textContent='3D ARENA'},2200);
    }finally{toggle.disabled=false;}
  }
  toggle.addEventListener('click',()=>{if(enabled)setEnabled(false);else setEnabled(true);});
  const gameScreen=document.getElementById('game');
  if(gameScreen){
    const gameObserver=new MutationObserver(()=>{
      if(gameScreen.hidden&&enabled)setEnabled(false);
    });
    gameObserver.observe(gameScreen,{attributes:true,attributeFilter:['hidden']});
  }
  document.addEventListener('visibilitychange',()=>{if(document.hidden&&raf){cancelAnimationFrame(raf);raf=0;}else if(!document.hidden&&enabled){sync();lastSyncAt=performance.now();if(!raf){lastFrameAt=0;animate();}}});
})();