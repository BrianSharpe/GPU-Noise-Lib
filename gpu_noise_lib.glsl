//
//	Code repository for GPU noise development blog
//	http://briansharpe.wordpress.com
//	https://github.com/BrianSharpe
//
//	I'm not one for copywrites.  Use the code however you wish.
//	All I ask is that credit be given back to the blog or myself when appropriate.
//	And also to let me know if you come up with any changes, improvements, thoughts or interesting uses for this stuff. :)
//	Thanks!
//
//	Brian Sharpe
//	brisharpe@yahoo.com
//	http://briansharpe.wordpress.com
//	https://github.com/BrianSharpe
//


//
//	NoiseLib TODO
//
//	1) Ensure portability across different cards
//	2) 16bit and 24bit implementations of hashes and noises
//	3) Lift various noise implementations out to individual self-contained files
//	4) Implement texture-based versions
//

//
//	Permutation polynomial idea is from Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//	http://www.itn.liu.se/~stegu/GLSL-cellular
//
//	http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
//
vec4 SGPP_coord_prepare(vec4 x) { return x - floor(x * ( 1.0 / 289.0 )) * 289.0; }		//	its good to keep the domain odd.  ( eg for polka dot noise )
vec3 SGPP_coord_prepare(vec3 x) { return x - floor(x * ( 1.0 / 289.0 )) * 289.0; }
vec4 SGPP_permute(vec4 x) { return fract( x * ( ( 34.0 / 289.0 ) * x + ( 1.0 / 289.0 ) ) ) * 289.0; }
vec4 SGPP_resolve(vec4 x) { return fract( x * ( 7.0 / 288.0 ) ); }
vec4 SGPP_hash_2D( vec2 gridcell )
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = SGPP_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	return SGPP_resolve( SGPP_permute( SGPP_permute( hash_coord.xzxz ) + hash_coord.yyww ) );
}
void SGPP_hash_2D( vec2 gridcell, out vec4 hash_0, out vec4 hash_1 )
{
	//    gridcell is assumed to be an integer coordinate
	vec4 hash_coord = SGPP_coord_prepare( vec4( gridcell.xy, gridcell.xy + 1.0.xx ) );
	hash_0 = SGPP_permute( SGPP_permute( hash_coord.xzxz ) + hash_coord.yyww );
	hash_1 = SGPP_resolve( SGPP_permute( hash_0 ) );
	hash_0 = SGPP_resolve( hash_0 );
}
void SGPP_hash_3D( vec3 gridcell, out vec4 lowz_hash, out vec4 highz_hash )
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = SGPP_coord_prepare( gridcell );
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, 287.5.xxx ) );
	highz_hash = SGPP_permute( SGPP_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy ) + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash = SGPP_resolve( SGPP_permute( highz_hash + gridcell.zzzz ) );
	highz_hash = SGPP_resolve( SGPP_permute( highz_hash + gridcell_inc1.zzzz ) );
}
void SGPP_hash_3D( 	vec3 gridcell,
					out vec4 lowz_hash_0,
					out vec4 lowz_hash_1,
					out vec4 lowz_hash_2,
					out vec4 highz_hash_0,
					out vec4 highz_hash_1,
					out vec4 highz_hash_2	)
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = SGPP_coord_prepare( gridcell );
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, 287.5.xxx ) );
	highz_hash_2 = SGPP_permute( SGPP_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy ) + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	lowz_hash_0 = SGPP_resolve( lowz_hash_2 = SGPP_permute( highz_hash_2 + gridcell.zzzz ) );
	highz_hash_0 = SGPP_resolve( highz_hash_2 = SGPP_permute( highz_hash_2 + gridcell_inc1.zzzz ) );
	lowz_hash_1 = SGPP_resolve( lowz_hash_2 = SGPP_permute( lowz_hash_2 ) );
	highz_hash_1 = SGPP_resolve( highz_hash_2 = SGPP_permute( highz_hash_2 ) );
	lowz_hash_2 = SGPP_resolve( SGPP_permute( lowz_hash_2 ) );
	highz_hash_2 = SGPP_resolve( SGPP_permute( highz_hash_2 ) );
}
vec4 SGPP_hash_3D( vec3 gridcell )
{
	//    gridcell is assumed to be an integer coordinate
	gridcell = SGPP_coord_prepare( gridcell );
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, 287.5.xxx ) );
	vec4 hash = SGPP_permute( SGPP_permute( vec2( gridcell.x, gridcell_inc1.x ).xyxy ) + vec2( gridcell.y, gridcell_inc1.y ).xxyy );
	return SGPP_resolve( SGPP_permute( hash + gridcell.zzzz ) );		//	we only need 4 hash values, so just use the lowZ for the final permutation
}


//
//	implementation of the blumblumshub hash
//	as described in MNoise paper http://www.cs.umbc.edu/~olano/papers/mNoise.pdf
//
//	http://briansharpe.wordpress.com/2011/10/01/gpu-texture-free-noise/
//
vec4 BBS_coord_prepare(vec4 x) { return x - floor(x * ( 1.0 / 61.0 )) * 61.0; }		//	its good to keep the domain odd.  ( eg for polka dot noise )
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
	//	gridcell is assumed to be an integer coordinate

	//	was having precision issues here with 61.0.  60.0 fixes it.  need to test on other cards.
	gridcell = gridcell - floor(gridcell * ( 1.0 / 60.0 )) * 60.0;
	vec3 gridcell_inc1 = mix( gridcell + 1.0.xxx, 0.0.xxx, greaterThan( gridcell, 58.5.xxx ) );

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
	const vec2 OFFSET = vec2( 25.0, 161.0 );
	const float DOMAIN = 71.0;			//	its good to keep the domain odd.  ( eg for polka dot noise )
	const float SOMEPRIME = 643.0;
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;	//	truncate the domain
	P += OFFSET.xyxy;								//	offset to interesting part of the noise
	P *= P;											//	calculate and return the hash
	return fract( P.xzxz * P.yyww * ( 1.0 / SOMEPRIME ).xxxx );
}
void FAST32_hash_2D( vec2 gridcell, out vec4 hash_0, out vec4 hash_1 )
{
	//    gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 25.0, 161.0 );
	const float DOMAIN = 71.0;			//	its good to keep the domain odd.  ( eg for polka dot noise )
	const float SOMEPRIME_0 = 643.0;
	const float SOMEPRIME_1 = 538.0;
	//const float SOMEPRIME_2 = 514.0;		//	this is another good number, if anyone ever needs it....
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;
	P += OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	hash_0 = fract( P * ( 1.0 / SOMEPRIME_0 ).xxxx );
	hash_1 = fract( P * ( 1.0 / SOMEPRIME_1 ).xxxx );
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
	//BBS_hash_3D( Pi, hash_lowz, hash_highz );
	SGPP_hash_3D( Pi, hash_lowz, hash_highz );

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
	vec4 grad_results_0_0 = mix( vec2( Pf.y, Pf_min1.y ).xxyy, vec2( Pf.x, Pf_min1.x ).xyxy, lessThan( hash_lowz, 2.0.xxxx ) );
	vec4 grad_results_0_1 = mix( Pf.zzzz, vec2( Pf.y, Pf_min1.y ).xxyy, lessThan( hash_lowz, 1.0.xxxx ) );
	hash_lowz = fract( hash_lowz ) - 0.5;
	vec4 grad_results_0 = grad_results_0_0 * sign( hash_lowz ) + grad_results_0_1 * sign( abs( hash_lowz ) - 0.25.xxxx );

	hash_highz *= 3.0;
	vec4 grad_results_1_0 = mix( vec2( Pf.y, Pf_min1.y ).xxyy, vec2( Pf.x, Pf_min1.x ).xyxy, lessThan( hash_highz, 2.0.xxxx ) );
	vec4 grad_results_1_1 = mix( Pf_min1.zzzz, vec2( Pf.y, Pf_min1.y ).xxyy, lessThan( hash_highz, 1.0.xxxx ) );
	hash_highz = fract( hash_highz ) - 0.5;
	vec4 grad_results_1 = grad_results_1_0 * sign( hash_highz ) + grad_results_1_1 * sign( abs( hash_highz ) - 0.25.xxxx );

	//	blend the gradients and return
	vec3 blend = Interpolation_C2( Pf );
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec2 res1 = mix( res0.xy, res0.zw, blend.y );
	return mix( res1.x, res1.y, blend.x );

#else

	//
	//	lets speed things up a little by using the 8 corner gradients instead.
	//	Ken mentions using diagonals like this can cause "clumping", but we'll live with that.  This will also give us a range of > +-1.0
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
	return mix( res1.x, res1.y, blend.x ) * (1.0 / 1.2);	//	mult by (1.0 / 1.2) to scale back to an approximate -1.0->1.0 range  ( TODO: need to find out the extact range.  Initial thoughts suggest -1.5->1.5, but not getting that in practice... )

#endif
}


//	convert a 0.0->1.0 sample to a -1.0->1.0 sample weighted towards the extremes
vec4 Cellular_weight_samples( vec4 samples )
{
	samples = samples * 2.0 - 1.0;
	//return (1.0 - samples * samples) * sign(samples);	// square
	return (samples * samples * samples) - sign(samples);	// cubic (even more variance)
}

//
//	Cellular Noise 2D
//	Based off Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//
//	Speed up by using 2x2 search window instead of 3x3
//	produces range of 0.0->~1.0 ( max theoritical value of sqrt( 0.75^2 * 2.0 ) ~= 1.0607 for dist and ( 0.75^2 * 2.0 ) = 1.125 for dist sq, but should rarely reach that )
//
float Cellular2D(vec2 P)
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 ox, oy;
	FAST32_hash_2D( Pi, ox, oy );
	//SGPP_hash_2D( Pi, ox, oy );

	//	generate the 4 random points
#if 1
	//	restrict the random point offset to eliminate artifacts
	//	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
	const float JITTER_WINDOW = 0.25;	// 0.25 will guarentee no artifacts.  0.25 is the intersection on x of graphs f(x)=( (0.5+(0.5-x))^2 + (0.5-x)^2 ) and f(x)=( (0.5+x)^2 + x^2 )
	ox = Cellular_weight_samples( ox ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
	oy = Cellular_weight_samples( oy ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
#else
	//	non-weighted jitter window.  jitter window of 0.4 will give results similar to Stefans original implementation
	//	nicer looking, faster, but has minor artifacts.  ( discontinuities in signal )
	const float JITTER_WINDOW = 0.4;
	ox = ox * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
	oy = oy * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
#endif

	//	return the closest squared distance
	vec4 dx = Pf.xxxx - ox;
	vec4 dy = Pf.yyyy - oy;
	vec4 d = dx * dx + dy * dy;
	d.xy = min(d.xy, d.zw);
	return min(d.x, d.y);
}


//
//	Cellular Noise 3D
//	Based off Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//
//	Speed up by using 2x2x2 search window instead of 3x3x3
//	produces range of 0.0->~1.0  ( max theoritical value of sqrt( 0.666666^2 * 3.0 ) ~= 1.155 for dist and ( 0.666666^2 * 3.0 ) ~= 1.33333 for dist sq, but should rarely reach that )
//
float Cellular3D(vec3 P)
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 ox1, oy1, oz1, ox2, oy2, oz2;
	SGPP_hash_3D( Pi, ox1, oy1, oz1, ox2, oy2, oz2 );

	//	generate the 8 random points
#if 1
	//	restrict the random point offset to eliminate artifacts
	//	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
	const float JITTER_WINDOW = 0.166666666;	// 0.166666666 will guarentee no artifacts. It is the intersection on x of graphs f(x)=( (0.5 + (0.5-x))^2 + 2*((0.5-x)^2) ) and f(x)=( 2 * (( 0.5 + x )^2) + x * x )
	ox1 = Cellular_weight_samples( ox1 ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
	oy1 = Cellular_weight_samples( oy1 ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
	ox2 = Cellular_weight_samples( ox2 ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
	oy2 = Cellular_weight_samples( oy2 ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
	oz1 = Cellular_weight_samples( oz1 ) * JITTER_WINDOW + vec4(0.0, 0.0, 0.0, 0.0);
	oz2 = Cellular_weight_samples( oz2 ) * JITTER_WINDOW + vec4(1.0, 1.0, 1.0, 1.0);
#else
	//	non-weighted jitter window.  jitter window of 0.4 will give results similar to Stefans original implementation
	//	nicer looking, faster, but has minor artifacts.  ( discontinuities in signal )
	const float JITTER_WINDOW = 0.4;
	ox1 = ox1 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
	oy1 = oy1 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
	ox2 = ox2 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
	oy2 = oy2 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
	oz1 = oz1 * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, -JITTER_WINDOW, -JITTER_WINDOW);
	oz2 = oz2 * JITTER_WINDOW * 2.0 + vec4(1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
#endif

	//	return the closest squared distance
	vec4 dx1 = Pf.xxxx - ox1;
	vec4 dy1 = Pf.yyyy - oy1;
	vec4 dz1 = Pf.zzzz - oz1;
	vec4 dx2 = Pf.xxxx - ox2;
	vec4 dy2 = Pf.yyyy - oy2;
	vec4 dz2 = Pf.zzzz - oz2;
	vec4 d1 = dx1 * dx1 + dy1 * dy1 + dz1 * dz1;
	vec4 d2 = dx2 * dx2 + dy2 * dy2 + dz2 * dz2;
	d1 = min(d1, d2);
	d1.xy = min(d1.xy, d1.wz);
	return min(d1.x, d1.y);
}

//
//	PolkaDot Noise 2D
//
//	Generates a noise of smooth falloff polka dots.
//	Allow for control on value and radius
//	Return value range of 0.0 -> ValRange.x+ValRange.y
//
float PolkaDot2D( 	vec2 P,
					vec2 RadRange,		//	RadRange.x = low  RadRange.y = high-low  should generate a range of 2.0->LARGENUM   ( 2.0 is a large dot, LARGENUM is a small dot eg 20.0 )
					vec2 ValRange	)	//	ValRange.x = low  ValRange.y = high-low  should generate a range of 0.0->1.0
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;
	Pi *= 2.0;		//	Need to multiply by 2.0 here because we want to use all 4 corners once per cell.  No sharing with other cells.  It helps if the hash function has an odd domain.

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );

	//	user variables
	float RADIUS = hash.z * RadRange.y + RadRange.x;		//	NOTE: we can parallelize this.  ( but seems like the compiler does it automatically anyway? )
	float VALUE = hash.w * ValRange.y + ValRange.x;

	//	calc the noise and return
	Pf *= RADIUS.xx;
	Pf -= ( RADIUS.xx - 1.0.xx );
	Pf += hash.xy * ( RADIUS.xx - 2.0.xx );
	return Falloff_Xsq_C2_Fast( min( dot( Pf, Pf ), 1.0 ) ) * VALUE;
}
//	PolkaDot2D_FixedRadius, PolkaDot2D_FixedValue, PolkaDot2D_FixedRadius_FixedValue TODO

//
//	PolkaDot Noise 3D
//
//	Generates a noise of smooth falloff polka dots.
//	Allow for control on value and radius
//	Return value range of 0.0 -> ValRange.x+ValRange.y
//
float PolkaDot3D( 	vec3 P,
					vec2 RadRange,		//	RadRange.x = low  RadRange.y = high-low  should generate a range of 2.0->LARGENUM   ( 2.0 is a large dot, LARGENUM is a small dot eg 20.0 )
					vec2 ValRange	)	//	ValRange.x = low  ValRange.y = high-low  should generate a range of 0.0->1.0
{
	//	establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	Pi *= 2.0;		//	Need to multiply by 2.0 here because we want to use all 8 corners once per cell.  No sharing with other cells.  It helps if the hash function has an odd domain.

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_lowz, hash_highz;
	//BBS_hash_3D( Pi, hash_lowz, hash_highz );
	SGPP_hash_3D( Pi, hash_lowz, hash_highz );

	//	user variables
	float RADIUS = hash_lowz.w * RadRange.y + RadRange.x;		//	NOTE: we can parallelize this.  ( but seems like the compiler does it automatically anyway? )
	float VALUE = hash_highz.x * ValRange.y + ValRange.x;

	//	calc the noise and return
	Pf *= RADIUS.xxx;
	Pf -= ( RADIUS.xxx - 1.0.xxx );
	Pf += hash_lowz.xyz * ( RADIUS.xxx - 2.0.xxx );
	return Falloff_Xsq_C2_Fast( min( dot( Pf, Pf ), 1.0 ) ) * VALUE;
}
//	PolkaDot3D_FixedRadius, PolkaDot3D_FixedValue, PolkaDot3D_FixedRadius_FixedValue TODO

//
//	Stars2D
//
//	procedural texture for creating a starry background  ( NOTE: should be combined with a nebula/space-like texture )
//
float Stars2D(	vec2 P,
				float probability_threshold,		//	probability a star will be drawn  ( 0.0->1.0 )
				float max_dimness,					//	the maximal dimness of a star ( 0.0->1.0   0.0 = all stars bright,  1.0 = maximum variation )
				float radius	)					//	fixed radius for the stars
{
	//	establish our grid cell and unit position
	vec2 Pi = floor(P);
	vec2 Pf = P - Pi;
	Pi *= 2.0;		//	Need to multiply by 2.0 here because we want to use all 4 corners once per cell.  No sharing with other cells.  It helps if the hash function has an odd domain.

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash = FAST32_hash_2D( Pi );
	//vec4 hash = BBS_hash_2D( Pi );
	//vec4 hash = SGPP_hash_2D( Pi );
	//vec4 hash = BBS_hash_hq_2D( Pi );

	//	user variables
	float VALUE = 1.0 - max_dimness * hash.z;

	//	calc the noise and return
	Pf *= radius.xx;
	Pf -= ( radius.xx - 1.0.xx );
	Pf += hash.xy * ( radius.xx - 2.0.xx );
	//return Falloff_Xsq_C1( min( dot( Pf, Pf ), 1.0 ) ) * VALUE * step( hash.w, probability_threshold );		//	C1 here suggests that this only be used for texturing and not for displacement
	return ( hash.w < probability_threshold ) ? ( Falloff_Xsq_C1( min( dot( Pf, Pf ), 1.0 ) ) * VALUE ) : 0.0;		//	C1 here suggests that this only be used for texturing and not for displacement
}


