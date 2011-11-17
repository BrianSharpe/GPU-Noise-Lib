//
//	Code repository for GPU noise development blog
//	http://briansharpe.wordpress.com/
//
//	I'm not one for copywrites.  Use the code however you wish.
//	All I ask is that credit be given back to the blog or myself when appropriate.
//	And also to let me know if you come up with any changes, improvements, thoughts or interesting uses for this stuff. :)
//	Thanks!
//
//	Brian Sharpe
//	brisharpe@yahoo.com
//	http://briansharpe.wordpress.com/
//

#version 120


//
//	Permutation polynomial idea is from Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//	http://www.itn.liu.se/~stegu/GLSL-cellular 	
//
//	http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
//
vec4 SGPP_coord_prepare(vec4 x) { return x - floor(x * ( 1.0 / 289.0 )) * 289.0; }
vec3 SGPP_coord_prepare(vec3 x) { return x - floor(x * ( 1.0 / 289.0 )) * 289.0; }
vec4 SGPP_permute(vec4 x) { return fract( x * ( ( 34.0 / 289.0 ) * x + ( 1.0 / 289.0 ) ) ) * 289.0; }
vec4 SGPP_resolve(vec4 x) { return fract(x * ( 7.0 / 288.0 ) ); }
vec4 SGPP_hash_2D( vec2 gridcell ) 
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = SGPP_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	return SGPP_resolve( SGPP_permute( SGPP_permute( hash_coord.xzxz ) + hash_coord.yyww ) );
}
void SGPP_hash_3D( vec3 gridcell, out vec4 lowz_hash, out vec4 highz_hash ) 
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = SGPP_coord_prepare( gridcell );
	vec3 gridcell_inc1 = gridcell + 1.0.xxx;
	gridcell_inc1 = mix( gridcell_inc1, 0.0.xxx, equal( gridcell_inc1, 289.0.xxx ) );
	vec4 p = SGPP_permute( SGPP_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy ) + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash = SGPP_resolve( SGPP_permute( p + gridcell.zzzz ) );
	highz_hash = SGPP_resolve( SGPP_permute( p + gridcell_inc1.zzzz ) );
}


//
//	implementation of the blumblumshub hash
//	as described in MNoise paper http://www.cs.umbc.edu/~olano/papers/mNoise.pdf
//
//	http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
//
vec4 BBS_coord_prepare(vec4 x) { return x - floor(x * ( 1.0 / 61.0 )) * 61.0; }
vec3 BBS_coord_prepare(vec3 x) { return x - floor(x * ( 1.0 / 61.0 )) * 61.0; }
vec4 BBS_permute(vec4 x) { return fract( x * x * ( 1.0 / 61.0 )) * 61.0; }
vec4 BBS_permute_and_resolve(vec4 x) { return fract( x * x * ( 1.0 / 61.0 ) ); }
vec4 BBS_hash_2D( vec2 gridcell ) 
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = BBS_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	vec4 p = BBS_permute( hash_coord.xzxz /* * 7.0 */ ); // * 7.0 will increase variance close to origin
	return BBS_permute_and_resolve( p + hash_coord.yyww );
}
vec4 BBS_hash_hq_2D( vec2 gridcell ) 
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = BBS_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	vec4 p = BBS_permute( hash_coord.xzxz /* * 7.0 */ );  // * 7.0 will increase variance close to origin
	p = BBS_permute( p + hash_coord.yyww );
	return BBS_permute_and_resolve( p + hash_coord.xzxz );
}
void BBS_hash_3D( vec3 gridcell, out vec4 lowz_hash, out vec4 highz_hash )  
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = BBS_coord_prepare( gridcell );
	vec3 gridcell_inc1 = gridcell + 1.0.xxx;
	gridcell_inc1 = mix( gridcell_inc1, 0.0.xxx, equal( gridcell_inc1, 61.0.xxx ) );
	vec4 p = BBS_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy /* * 7.0 */ );  // * 7.0 will increase variance close to origin
	p = BBS_permute( p + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash = BBS_permute_and_resolve( p + gridcell.zzzz );
	highz_hash = BBS_permute_and_resolve( p + gridcell_inc1.zzzz );
}


//
//	FAST32_hash
//	A very fast hashing function.  Requires 32bit support.
//	http://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
//
//	The hash formula takes the form....
//	hash = mod( coord.x * coord.x * coord.y * coord.y, SOMEPRIME ) / SOMEPRIME
//	We truncate and offset the domain to the most interesting part of the noise.
//
vec4 FAST32_hash_2D( vec2 gridcell )
{	
	//	gridcell is assumed to be an integer coordinate
	
	//	tweakable settings....
	const vec2 OFFSET = vec2( 24.0, 160.0 );
	const float DOMAIN = 72.0;
	const float SOMEPRIME = 643.0;

	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;	//	truncate the domain
	P += OFFSET.xyxy;								//	offset to interesting part of the noise
	P *= P;											//	calculate and return the hash
	return fract( P.xzxz * P.yyww * ( 1.0 / SOMEPRIME ).xxxx );
}


//
//	Interpolation functions
//	( smoothly increase from 0.0 to 1.0 as x increases linearly from 0.0 to 1.0 )
//	http://briansharpe.wordpress.com/2011/11/14/two-useful-interpolation-functions-for-noise-development/
//

//	Hermine Curve.  Same as SmoothStep().  As used by Perlin in Original Noise.
//	3x^2-2x^3
float Interpolation_C1( float x ) { return x * x * (3.0 - 2.0 * x); }
vec2 Interpolation_C1( vec2 x ) { return x * x * (3.0 - 2.0 * x); }
vec3 Interpolation_C1( vec3 x ) { return x * x * (3.0 - 2.0 * x); }
vec4 Interpolation_C1( vec4 x ) { return x * x * (3.0 - 2.0 * x); }

//	Quintic Curve.  As used by Perlin in Improved Noise.  http://mrl.nyu.edu/~perlin/paper445.pdf
//	6x^5-15x^4+10x^3
float Interpolation_C2( float x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec2 Interpolation_C2( vec2 x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec3 Interpolation_C2( vec3 x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec4 Interpolation_C2( vec4 x ) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }

//	Faster than Perlin Quintic.  Not quite as good shape. 
//	7x^3-7x^4+x^7
float Interpolation_C2_Fast( float x ) { float x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }
vec2 Interpolation_C2_Fast( vec2 x ) { vec2 x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }
vec3 Interpolation_C2_Fast( vec3 x ) { vec3 x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }
vec4 Interpolation_C2_Fast( vec4 x ) { vec4 x3 = x*x*x; return ( 7.0 + ( x3 - 7.0 ) * x ) * x3; }

//	C3 Interpolation function.  If anyone ever needs it... :)
//	25x^4-48x^5+25x^6-x^10
float Interpolation_C3( float x ) { float xsq = x*x; float xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }
vec2 Interpolation_C3( vec2 x ) { vec2 xsq = x*x; vec2 xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }
vec3 Interpolation_C3( vec3 x ) { vec3 xsq = x*x; vec3 xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }
vec4 Interpolation_C3( vec4 x ) { vec4 xsq = x*x; vec4 xsqsq = xsq*xsq; return xsqsq * ( 25.0 - 48.0 * x + xsq * ( 25.0 - xsqsq ) ); }


//
//	Falloff functions defined in XSquared
//	( smooth falloff from 1.0 to 0.0 as xsq ranges from 0.0 to 1.0.  Suitable for fading out from a point via dot product )
//	http://briansharpe.wordpress.com/2011/11/14/two-useful-interpolation-functions-for-noise-development/
//

//	C1 XSquared Falloff
//	Used by Humus for lighting falloff in Just Cause 2.  
//  "Making it large, beautiful, fast and consistent – Lessons learned developing Just Cause 2 by Emil Persson", GPUPro 1
//	( 1.0 - x*x )^2
float Falloff_Xsq_C1( float xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }
vec2 Falloff_Xsq_C1( vec2 xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }
vec3 Falloff_Xsq_C1( vec3 xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }
vec4 Falloff_Xsq_C1( vec4 xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }

//	C2 XSquared Falloff
//	1.0 - ( 9x^4-16x^6+9x^8-x^12 )
float Falloff_Xsq_C2( float xsq ) { float xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }
vec2 Falloff_Xsq_C2( vec2 xsq ) { vec2 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }
vec3 Falloff_Xsq_C2( vec3 xsq ) { vec3 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }
vec4 Falloff_Xsq_C2( vec4 xsq ) { vec4 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 9.0 - 16.0 * xsq + xsqsq * ( 9.0 - xsqsq ) ); }

//	Fast C2 XSquared falloff
//	1.0 - ( 5x^4-5x^6+x^10 )      NOTE: alternative could be this.  1.0 - ( 3x^4-3x^8+x^12 ).  Shape not quite as good but requires no extra registers
float Falloff_Xsq_C2_Fast( float xsq ) { float xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }
vec2 Falloff_Xsq_C2_Fast( vec2 xsq ) { vec2 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }
vec3 Falloff_Xsq_C2_Fast( vec3 xsq ) { vec3 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }
vec4 Falloff_Xsq_C2_Fast( vec4 xsq ) { vec4 xsqsq = xsq*xsq; return 1.0 - xsqsq * ( 5.0 + xsq * ( xsqsq - 5.0 ) ); }

//	C3 XSquared falloff.  If anyone ever needs it... :)
//	1.0 - ( 10x^4-20x^6+15x^8-4x^10 )
float Falloff_Xsq_C3( float xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }
vec2 Falloff_Xsq_C3( vec2 xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }
vec3 Falloff_Xsq_C3( vec3 xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }
vec4 Falloff_Xsq_C3( vec4 xsq ) {	return 1.0 - xsq * xsq * ( 10.0 + xsq * ( xsq * ( 15.0 - 4.0 * xsq ) - 20.0 ) ); }



//
//	Lattice Noise 2D
//	Return value range of 0.0->1.0
//
float Lattice2D( vec2 P )
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;
	
	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );
	
	//	blend the results and return
	vec2 blend = Interpolation_C2( Pf );
	vec2 res0 = mix( hash.xy, hash.zw, blend.y );
	return mix( res0.x, res0.y, blend.x );
}

//
//	Lattice Noise 3D
//	Return value range of 0.0->1.0
//
float Lattice3D( vec3 P )
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	
	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_lowz, hash_highz;
	BBS_hash_3D( Pi, hash_lowz, hash_highz );
	//SGPP_hash_3D( Pi, hash_lowz, hash_highz );
	
	//	blend the results and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( hash_lowz, hash_highz, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x );
}


//
//	Perlin Noise 2D
//	Return value range of -1.0->1.0
//
float Perlin2D( vec2 P )
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec4 Pf_Pfmin1 = P.xyxy - vec4( Pi, Pi + 1.0.xx );
	
	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );
	
	//	evaulate the gradients
#if 0
	//
	//	choose between the 4 axis aligned gradients.  
	//	[-1.0,0.0] [1.0,0.0] [0.0,-1.0] [0.0,1.0]
	//
	vec4 grad_results = mix( Pf_Pfmin1.xzxz, Pf_Pfmin1.yyww, lessThan( hash, 0.5.xxxx ) );
	grad_results = mix( grad_results, -grad_results, lessThan( abs( hash - 0.5.xxxx ), 0.25.xxxx ) );
#else
	//
	//	choose between the 4 diagonal gradients.  ( slightly slower but shows less grid artifacts )
	//	[1.0,1.0] [-1.0,1.0] [1.0,-1.0] [-1.0,-1.0]
	//
	hash -= 0.5.xxxx;
	vec4 grad_results = Pf_Pfmin1.xzxz * sign( hash ) + Pf_Pfmin1.yyww * sign( abs( hash ) - 0.25.xxxx );
#endif

	//	blend the results and return
	vec2 blend = Interpolation_C2( Pf_Pfmin1.xy );
	vec2 res0 = mix( grad_results.xy, grad_results.zw, blend.y );
	return mix( res0.x, res0.y, blend.x );
}


//
//	Perlin Noise 2D
//	Return value range of -1.0->1.0
//
float Perlin3D( vec3 P )
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	vec3 Pf_min1 = Pf - 1.0;
	
	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_lowz, hash_highz;
	//BBS_hash_3D( Pi, hash_lowz, hash_highz );
	SGPP_hash_3D( Pi, hash_lowz, hash_highz );
	
	//	evaulate gradients
#if 0

	//
	//	this will implement Ken Perlins "improved" classic noise using the 12 mid-edge gradient points.
	//	[1,1,0] [-1,1,0] [1,-1,0] [-1,-1,0]
	//	[1,0,1] [-1,0,1] [1,0,-1] [-1,0,-1]
	//	[0,1,1] [0,-1,1] [0,1,-1] [0,-1,-1]
	//
	hash_lowz *= 3.0;
	vec4 grad_results_0_0 = mix( vec4( Pf.yy, Pf_min1.yy ), vec4( Pf.x, Pf_min1.x, Pf.x, Pf_min1.x ), lessThan( hash_lowz, 2.0.xxxx ) );
	vec4 grad_results_0_1 = mix( vec4( Pf.zzzz ), vec4( Pf.yy, Pf_min1.yy ), lessThan( hash_lowz, 1.0.xxxx ) );
	hash_lowz = fract( hash_lowz ) - 0.5;
	vec4 grad_results_0 = grad_results_0_0 * sign( hash_lowz ) + grad_results_0_1 * sign( abs( hash_lowz ) - 0.25.xxxx );
	
	hash_highz *= 3.0;
	vec4 grad_results_1_0 = mix( vec4( Pf.yy, Pf_min1.yy ), vec4( Pf.x, Pf_min1.x, Pf.x, Pf_min1.x ), lessThan( hash_highz, 2.0.xxxx ) );
	vec4 grad_results_1_1 = mix( vec4( Pf_min1.zzzz ), vec4( Pf.yy, Pf_min1.yy ), lessThan( hash_highz, 1.0.xxxx ) );
	hash_highz = fract( hash_highz ) - 0.5;
	vec4 grad_results_1 = grad_results_1_0 * sign( hash_highz ) + grad_results_1_1 * sign( abs( hash_highz ) - 0.25.xxxx );
	
	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x );
	
#else

	//
	//	lets speed things up a little by using the 8 corner gradients instead. ( Ken mentions using diagonals like this can cause "clumping", but we'll live with that )
	//	[1,1,1]  [-1,1,1]  [1,-1,1]  [-1,-1,1]
	//	[1,1,-1] [-1,1,-1] [1,-1,-1] [-1,-1,-1]
	//
	hash_lowz -= 0.5.xxxx;
	vec4 grad_results_0_0 = vec2( Pf.x, Pf_min1.x ).xyxy * sign( hash_lowz );
	hash_lowz = abs( hash_lowz ) - 0.25.xxxx;
	vec4 grad_results_0_1 = vec2( Pf.y, Pf_min1.y ).xxyy * sign( hash_lowz );
	vec4 grad_results_0_2 = Pf.zzzz * sign( abs( hash_lowz ) - 0.125.xxxx );
	vec4 grad_results_0 = grad_results_0_0 + grad_results_0_1 + grad_results_0_2;
	
	hash_highz -= 0.5.xxxx;
	vec4 grad_results_1_0 = vec2( Pf.x, Pf_min1.x ).xyxy * sign( hash_highz );
	hash_highz = abs( hash_highz ) - 0.25.xxxx;
	vec4 grad_results_1_1 = vec2( Pf.y, Pf_min1.y ).xxyy * sign( hash_highz );
	vec4 grad_results_1_2 = Pf_min1.zzzz * sign( abs( hash_highz ) - 0.125.xxxx );
	vec4 grad_results_1 = grad_results_1_0 + grad_results_1_1 + grad_results_1_2;
	
	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x ) * (2.0 / 3.0);	//	mult by (2.0 / 3.0) to scale back to -1.0->1.0 range
	
#endif
}

