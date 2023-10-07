struct VertexInput {
  @location(0) pos: vec2f,
  @builtin(instance_index) instance: u32,
  @builtin(vertex_index) vertIndex: u32
};

struct VertexOutput {
  @builtin(position) pos: vec4f,
  @location(0) localPos: vec2f,
  @location(1) scale: vec2f
};

struct Particle {
  pos: vec2f,
  speed: f32
};

@group(0) @binding(0) var<uniform> frame: f32;
@group(0) @binding(1) var<uniform> res:   vec2f;
@group(0) @binding(2) var<uniform> noiseChangeRate:   f32;
@group(0) @binding(3) var<uniform> bubbleSize:   f32;
@group(0) @binding(4) var<storage> state: array<Particle>;

fn noise(p : vec2f) -> vec2f {
  return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

@vertex
fn vs( input: VertexInput ) -> VertexOutput {
  let p = state[ input.instance ];

  let aspect = res.y / res.x;

  let scale = vec2f(1) * .3 * ((saturate(cos(p.pos.x/200))/4. + 0.8)) * (p.pos.y/2. + 0.5);

  let size = input.pos * scale * (bubbleSize * 2.);

  // Credit to Milo Jacobs for this hack for local particle position
  let localPosArray = array<vec2f,6>(
    //Bottom right
    vec2f(1,0),
    //Bottom left
    vec2f(0,0),
    //Top left
    vec2f(0,1),
    //Bottom right
    vec2f(1,0),
    //Top left
    vec2f(0,1),
    //Top right
    vec2f(1,1)
  );

  return VertexOutput(vec4f(p.pos.x - size.x * aspect, p.pos.y + size.y, 0., 1.), localPosArray[input.vertIndex], scale);
}

@fragment 
fn fs( vInfo : VertexOutput ) -> @location(0) vec4f {;
  let pos : vec4f = vInfo.pos;
  let localPos : vec2f = vInfo.localPos;
  let scale : vec2f = vInfo.scale;

  let p : vec2f = vec2f(pos.x, pos.y) / res;

  let pixels : vec2f = ((floor((pos + vec4f(0., frame/5., 0., 0.))/100.) * 100.)).xy / res;
  let random = noise(pixels+floor((frame*2.*noiseChangeRate)/600));

  var outColor : vec3f = vec3f(0, 0, 0);
  switch (i32(floor(saturate(random.x) * 3))) {
    case 0:
    {
      outColor = vec3f(0xD6/255., 0x5B/255., 0x58/255.);
      break;
    }
    case 1:
    {
      outColor = vec3f(0xFF/255., 0x66/255., 0x63/255.);
      break;
    }
    case 2:
    {
      outColor = vec3f(0xFE/255., 0x7F/255., 0x74/255.);
      break;
    }
    default:
    {
      outColor = vec3f(0xFE/255., 0x7F/255., 0x74/255.);
    }
  }

  var fizzyColor : vec3f = vec3f(0xFA/255., 0xFA/255., 0xC6/255.);

  let fizzyPixels : vec2f = (floor(pos/10.) * 10.).xy / res;

  var heightDither: f32 = pow(1 - (p.y), 10);
  if (heightDither > noise(fizzyPixels+floor((frame*2.*noiseChangeRate)/15)).x) {
    heightDither += .2;
  }

  outColor = mix(outColor, fizzyColor, heightDither);



  let dist = distance(localPos, vec2f(0.5));

  if(dist < (0.9 * (scale.y * sin(frame/60.)) + 0.13) || dist < (0.5 * (scale.x)) || dist > 0.5) {
    discard;
  }

  //if(dist < (0.5 * (scale.x)) || dist > 0.5) {
  //  discard;
  //}
  //else if()


  return vec4f(outColor, 0.7);
}
