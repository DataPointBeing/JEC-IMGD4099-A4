import { default as seagulls } from './seagulls/seagulls.js'
import { Pane } from 'https://cdn.jsdelivr.net/npm/tweakpane@4.0.1/dist/tweakpane.min.js';

const WORKGROUP_SIZE = 8;

let frame = 0;

const sg = await seagulls.init(),
   render_shader  = await seagulls.import( './render.wgsl' ),
   compute_shader = await seagulls.import( './compute.wgsl' );

const NUM_PARTICLES = 200,
   // must be evenly divisble by 4 to use wgsl structs
   NUM_PROPERTIES = 4,
   state = new Float32Array( NUM_PARTICLES * NUM_PROPERTIES );

for( let i = 0; i < NUM_PARTICLES * NUM_PROPERTIES; i+= NUM_PROPERTIES ) {
  state[ i ] = -1 + Math.random() * 2;
  state[ i + 1 ] = -1 + Math.random() * 2;
  state[ i + 2 ] = Math.random();
}

// tweakpane stuff
const tpParams = {
  noiseChangeRate: 0.5,
  bubbleSize: 0.5,
  bubbleCount: NUM_PARTICLES
};

const pane = new Pane();
pane.addBinding(tpParams, 'noiseChangeRate', {min: 0, max: 1 }).on('change',  e => {sg.uniforms.noiseChangeRate = e.value;});
pane.addBinding(tpParams, 'bubbleSize', {min: 0, max: 1 }).on('change',  e => {sg.uniforms.bubbleSize = e.value;});
pane.addBinding(tpParams, 'bubbleCount', {step: 1, min: 1, max: NUM_PARTICLES }).on('change',  e => {
   sg.uniforms.bubbleCount = e.value;
   sg.run(e.value)
});

sg.buffers({ state })
   .backbuffer(false)
   .clear( [0x32/255,0x31/255,0x2E/255,1] )
   .blend( true )
   .uniforms({
     frame,
     res:[sg.width, sg.height ],
     noiseChangeRate: tpParams.noiseChangeRate,
     bubbleSize: tpParams.bubbleSize
   })
   .compute( compute_shader, NUM_PARTICLES / (WORKGROUP_SIZE*WORKGROUP_SIZE) )
   .render( render_shader )
   .onframe( ()=>  sg.uniforms.frame = frame++  )
   .run(NUM_PARTICLES);

