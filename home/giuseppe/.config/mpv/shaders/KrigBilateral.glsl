//// N.B. This is a customized version by giuseppe998e
// KrigBilateral by Shiandow
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3.0 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library.

//!HOOK CHROMA
//!BIND HOOKED
//!BIND LUMA
//!SAVE LOWRES_Y
//!WIDTH LUMA.w
//!WHEN CHROMA.w LUMA.w <
//!DESC KrigBilateral Downscaling Y pass 1

#define OFFSET    vec2(0)
#define AXIS      1
#define KERNEL(X) (dot(vec3(0.42659, -0.49656, 0.076849), cos(vec3(0, 1, 2) * acos(-1.0) * (X + 1.0))))

vec4 hook() {
    // Calculate bounds
    float low  =  ceil((LUMA_pos - CHROMA_pt) * LUMA_size - OFFSET - 0.5)[AXIS],
          high = floor((LUMA_pos + CHROMA_pt) * LUMA_size - OFFSET - 0.5)[AXIS];

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = LUMA_pos;

    for (float k = low; k <= high; k++) {
        pos[AXIS] = LUMA_pt[AXIS] * (k - OFFSET[AXIS] + 0.5);

        vec4 y = textureGrad(LUMA_raw, pos, vec2(0.0), vec2(0.0)).xxxx * LUMA_mul;
        y.y *= y.y;

        float rel = (pos[AXIS] - LUMA_pos[AXIS])*CHROMA_size[AXIS];
        float w = KERNEL(rel);
        avg += w * y;
        W += w;
    }

    avg /= W;
    avg.y = abs(avg.y - avg.x * avg.x);
    return avg;
}

// -------------------------------------------------------------------------------------------------------------------

//!HOOK CHROMA
//!BIND HOOKED
//!BIND LOWRES_Y
//!SAVE LOWRES_Y
//!WHEN CHROMA.w LUMA.w <
//!DESC KrigBilateral Downscaling Y pass 2

#define OFFSET    vec2(0)
#define AXIS      1
#define KERNEL(X) (dot(vec3(0.42659, -0.49656, 0.076849), cos(vec3(0, 1, 2) * acos(-1.0) * (X + 1.0))))

vec4 hook() {
    // Calculate bounds
    float low  =  ceil((LOWRES_Y_pos - CHROMA_pt) * LOWRES_Y_size - OFFSET - 0.5)[AXIS],
          high = floor((LOWRES_Y_pos + CHROMA_pt) * LOWRES_Y_size - OFFSET - 0.5)[AXIS];

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = LOWRES_Y_pos;

    for (float k = low; k <= high; k++) {
        pos[AXIS] = LOWRES_Y_pt[AXIS] * (k - OFFSET[AXIS] + 0.5);

        vec4 y = textureGrad(LOWRES_Y_raw, pos, vec2(0.0), vec2(0.0)).xxxx * LOWRES_Y_mul;
        y.y *= y.y;

        float rel = (pos[AXIS] - LOWRES_Y_pos[AXIS]) * CHROMA_size[AXIS];
        float w = KERNEL(rel);
        avg += w * y;
        W += w;
    }

    avg /= W;
    avg.y = abs(avg.y - avg.x * avg.x) + LOWRES_Y_texOff(0).y;
    return avg;
}

// -------------------------------------------------------------------------------------------------------------------

//!HOOK CHROMA
//!BIND HOOKED
//!BIND LUMA
//!BIND LOWRES_Y
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!OFFSET ALIGN
//!DESC KrigBilateral Upscaling UV

#define N 8
#define RADIUS 1.0
#define SIGMA_NSQ (256.0 / (255.0 * 255.0))

#define SQR(X) dot(X, X)

#define M(I, J) Mx[min(I, J) * N + max(I, J) - (min(I, J) * (min(I, J) + 1)) / 2]

#define  C(I)    (inversesqrt(1.0 +  X[I].y           / var) * exp(-0.5 * (SQR(X[I].x - y)      / (localVar + X[I].y)           + SQR((coords[I] - offset)    / RADIUS))))
#define CC(I, J) (inversesqrt(1.0 + (X[I].y + X[J].y) / var) * exp(-0.5 * (SQR(X[I].x - X[J].x) / (localVar + X[I].y  + X[J].y) + SQR((coords[I] - coords[J]) / RADIUS))) /*+ (X[I].x - y) * (X[J].x - y) / var*/)  // commented out part works well only on test patterns

#define I3(F, N) F(N) F(N + 1) F(N + 2)
#define I9(F, N) I3(F, N) I3(F, N + 3) I3(F, N + 6)

#define GETNSUM(I)                                                                                                                       \
    X[I] = vec4(LOWRES_Y_tex(LOWRES_Y_pt * (pos + coords[I] + vec2(0.5))).xy, CHROMA_tex(CHROMA_pt * (pos + coords[I] + vec2(0.5))).xy); \
    w = clamp(1.5 - abs(coords[I]), 0.0, 1.0);                                                                                           \
    total += w.x * w.y * vec4(X[I].x, X[I].x * X[I].x, X[I].y, 1.0);

vec4 hook() {
    vec2 pos = CHROMA_pos * HOOKED_size - vec2(0.5);
    vec2 offset = pos - round(pos);
    pos -= offset;

    vec2 coords[N + 1];
    vec4 X[N + 1];
    vec2 w;
    vec4 total = vec4(0);

    coords[0] = vec2(-1, -1); coords[1] = vec2(-1, 0); coords[2] = vec2(-1,  1);
    coords[3] = vec2( 0, -1); coords[4] = vec2( 0, 1); coords[5] = vec2( 1, -1);
    coords[6] = vec2( 1,  0); coords[7] = vec2( 1, 1); coords[8] = vec2( 0,  0);

    I9(GETNSUM, 0)

    total.xyz /= total.w;
    float localVar = abs(total.y - total.x * total.x) + SIGMA_NSQ;
    float var = localVar + total.z;

    float y = LUMA_texOff(0).x;
    float Mx[(N * (N + 1)) / 2];
    float b[N];
    vec2 interp = X[N].zw;

    b[0] = C(0) - C(N) - CC(0, N) + CC(N, N); M(0, 0) = CC(0, 0) - CC(0, N) - CC(0, N) + CC(N, N); M(0, 1) = CC(0, 1) - CC(1, N) - CC(0, N) + CC(N, N); M(0, 2) = CC(0, 2) - CC(2, N) - CC(0, N) + CC(N, N); M(0, 3) = CC(0, 3) - CC(3, N) - CC(0, N) + CC(N, N); M(0, 4) = CC(0, 4) - CC(4, N) - CC(0, N) + CC(N, N); M(0, 5) = CC(0, 5) - CC(5, N) - CC(0, N) + CC(N, N); M(0, 6) = CC(0, 6) - CC(6, N) - CC(0, N) + CC(N, N); M(0, 7) = CC(0, 7) - CC(7, N) - CC(0, N) + CC(N, N);
    b[1] = C(1) - C(N) - CC(1, N) + CC(N, N); M(1, 1) = CC(1, 1) - CC(1, N) - CC(1, N) + CC(N, N); M(1, 2) = CC(1, 2) - CC(2, N) - CC(1, N) + CC(N, N); M(1, 3) = CC(1, 3) - CC(3, N) - CC(1, N) + CC(N, N); M(1, 4) = CC(1, 4) - CC(4, N) - CC(1, N) + CC(N, N); M(1, 5) = CC(1, 5) - CC(5, N) - CC(1, N) + CC(N, N); M(1, 6) = CC(1, 6) - CC(6, N) - CC(1, N) + CC(N, N); M(1, 7) = CC(1, 7) - CC(7, N) - CC(1, N) + CC(N, N);
    b[2] = C(2) - C(N) - CC(2, N) + CC(N, N); M(2, 2) = CC(2, 2) - CC(2, N) - CC(2, N) + CC(N, N); M(2, 3) = CC(2, 3) - CC(3, N) - CC(2, N) + CC(N, N); M(2, 4) = CC(2, 4) - CC(4, N) - CC(2, N) + CC(N, N); M(2, 5) = CC(2, 5) - CC(5, N) - CC(2, N) + CC(N, N); M(2, 6) = CC(2, 6) - CC(6, N) - CC(2, N) + CC(N, N); M(2, 7) = CC(2, 7) - CC(7, N) - CC(2, N) + CC(N, N);
    b[3] = C(3) - C(N) - CC(3, N) + CC(N, N); M(3, 3) = CC(3, 3) - CC(3, N) - CC(3, N) + CC(N, N); M(3, 4) = CC(3, 4) - CC(4, N) - CC(3, N) + CC(N, N); M(3, 5) = CC(3, 5) - CC(5, N) - CC(3, N) + CC(N, N); M(3, 6) = CC(3, 6) - CC(6, N) - CC(3, N) + CC(N, N); M(3, 7) = CC(3, 7) - CC(7, N) - CC(3, N) + CC(N, N);
    b[4] = C(4) - C(N) - CC(4, N) + CC(N, N); M(4, 4) = CC(4, 4) - CC(4, N) - CC(4, N) + CC(N, N); M(4, 5) = CC(4, 5) - CC(5, N) - CC(4, N) + CC(N, N); M(4, 6) = CC(4, 6) - CC(6, N) - CC(4, N) + CC(N, N); M(4, 7) = CC(4, 7) - CC(7, N) - CC(4, N) + CC(N, N);
    b[5] = C(5) - C(N) - CC(5, N) + CC(N, N); M(5, 5) = CC(5, 5) - CC(5, N) - CC(5, N) + CC(N, N); M(5, 6) = CC(5, 6) - CC(6, N) - CC(5, N) + CC(N, N); M(5, 7) = CC(5, 7) - CC(7, N) - CC(5, N) + CC(N, N);
    b[6] = C(6) - C(N) - CC(6, N) + CC(N, N); M(6, 6) = CC(6, 6) - CC(6, N) - CC(6, N) + CC(N, N); M(6, 7) = CC(6, 7) - CC(7, N) - CC(6, N) + CC(N, N);
    b[7] = C(7) - C(N) - CC(7, N) + CC(N, N); M(7, 7) = CC(7, 7) - CC(7, N) - CC(7, N) + CC(N, N);

    b[1] -= b[0] * M(0, 1) / M(0, 0); M(1, 1) -= M(0, 1) * M(0, 1) / M(0, 0); M(1, 2) -= M(0, 2) * M(0, 1) / M(0, 0); M(1, 3) -= M(0, 3) * M(0, 1) / M(0, 0); M(1, 4) -= M(0, 4) * M(0, 1) / M(0, 0); M(1, 5) -= M(0, 5) * M(0, 1) / M(0, 0); M(1, 6) -= M(0, 6) * M(0, 1) / M(0, 0); M(1, 7) -= M(0, 7) * M(0, 1) / M(0, 0);
    b[2] -= b[0] * M(0, 2) / M(0, 0); M(2, 2) -= M(0, 2) * M(0, 2) / M(0, 0); M(2, 3) -= M(0, 3) * M(0, 2) / M(0, 0); M(2, 4) -= M(0, 4) * M(0, 2) / M(0, 0); M(2, 5) -= M(0, 5) * M(0, 2) / M(0, 0); M(2, 6) -= M(0, 6) * M(0, 2) / M(0, 0); M(2, 7) -= M(0, 7) * M(0, 2) / M(0, 0);
    b[3] -= b[0] * M(0, 3) / M(0, 0); M(3, 3) -= M(0, 3) * M(0, 3) / M(0, 0); M(3, 4) -= M(0, 4) * M(0, 3) / M(0, 0); M(3, 5) -= M(0, 5) * M(0, 3) / M(0, 0); M(3, 6) -= M(0, 6) * M(0, 3) / M(0, 0); M(3, 7) -= M(0, 7) * M(0, 3) / M(0, 0);
    b[4] -= b[0] * M(0, 4) / M(0, 0); M(4, 4) -= M(0, 4) * M(0, 4) / M(0, 0); M(4, 5) -= M(0, 5) * M(0, 4) / M(0, 0); M(4, 6) -= M(0, 6) * M(0, 4) / M(0, 0); M(4, 7) -= M(0, 7) * M(0, 4) / M(0, 0);
    b[5] -= b[0] * M(0, 5) / M(0, 0); M(5, 5) -= M(0, 5) * M(0, 5) / M(0, 0); M(5, 6) -= M(0, 6) * M(0, 5) / M(0, 0); M(5, 7) -= M(0, 7) * M(0, 5) / M(0, 0);
    b[6] -= b[0] * M(0, 6) / M(0, 0); M(6, 6) -= M(0, 6) * M(0, 6) / M(0, 0); M(6, 7) -= M(0, 7) * M(0, 6) / M(0, 0);
    b[7] -= b[0] * M(0, 7) / M(0, 0); M(7, 7) -= M(0, 7) * M(0, 7) / M(0, 0);

    b[2] -= b[1] * M(1, 2) / M(1, 1); M(2, 2) -= M(1, 2) * M(1, 2) / M(1, 1); M(2, 3) -= M(1, 3) * M(1, 2) / M(1, 1); M(2, 4) -= M(1, 4) * M(1, 2) / M(1, 1); M(2, 5) -= M(1, 5) * M(1, 2) / M(1, 1); M(2, 6) -= M(1, 6) * M(1, 2) / M(1, 1); M(2, 7) -= M(1, 7) * M(1, 2) / M(1, 1);
    b[3] -= b[1] * M(1, 3) / M(1, 1); M(3, 3) -= M(1, 3) * M(1, 3) / M(1, 1); M(3, 4) -= M(1, 4) * M(1, 3) / M(1, 1); M(3, 5) -= M(1, 5) * M(1, 3) / M(1, 1); M(3, 6) -= M(1, 6) * M(1, 3) / M(1, 1); M(3, 7) -= M(1, 7) * M(1, 3) / M(1, 1);
    b[4] -= b[1] * M(1, 4) / M(1, 1); M(4, 4) -= M(1, 4) * M(1, 4) / M(1, 1); M(4, 5) -= M(1, 5) * M(1, 4) / M(1, 1); M(4, 6) -= M(1, 6) * M(1, 4) / M(1, 1); M(4, 7) -= M(1, 7) * M(1, 4) / M(1, 1);
    b[5] -= b[1] * M(1, 5) / M(1, 1); M(5, 5) -= M(1, 5) * M(1, 5) / M(1, 1); M(5, 6) -= M(1, 6) * M(1, 5) / M(1, 1); M(5, 7) -= M(1, 7) * M(1, 5) / M(1, 1);
    b[6] -= b[1] * M(1, 6) / M(1, 1); M(6, 6) -= M(1, 6) * M(1, 6) / M(1, 1); M(6, 7) -= M(1, 7) * M(1, 6) / M(1, 1);
    b[7] -= b[1] * M(1, 7) / M(1, 1); M(7, 7) -= M(1, 7) * M(1, 7) / M(1, 1);

    b[3] -= b[2] * M(2, 3) / M(2, 2); M(3, 3) -= M(2, 3) * M(2, 3) / M(2, 2); M(3, 4) -= M(2, 4) * M(2, 3) / M(2, 2); M(3, 5) -= M(2, 5) * M(2, 3) / M(2, 2); M(3, 6) -= M(2, 6) * M(2, 3) / M(2, 2); M(3, 7) -= M(2, 7) * M(2, 3) / M(2, 2);
    b[4] -= b[2] * M(2, 4) / M(2, 2); M(4, 4) -= M(2, 4) * M(2, 4) / M(2, 2); M(4, 5) -= M(2, 5) * M(2, 4) / M(2, 2); M(4, 6) -= M(2, 6) * M(2, 4) / M(2, 2); M(4, 7) -= M(2, 7) * M(2, 4) / M(2, 2);
    b[5] -= b[2] * M(2, 5) / M(2, 2); M(5, 5) -= M(2, 5) * M(2, 5) / M(2, 2); M(5, 6) -= M(2, 6) * M(2, 5) / M(2, 2); M(5, 7) -= M(2, 7) * M(2, 5) / M(2, 2);
    b[6] -= b[2] * M(2, 6) / M(2, 2); M(6, 6) -= M(2, 6) * M(2, 6) / M(2, 2); M(6, 7) -= M(2, 7) * M(2, 6) / M(2, 2);
    b[7] -= b[2] * M(2, 7) / M(2, 2); M(7, 7) -= M(2, 7) * M(2, 7) / M(2, 2);

    b[4] -= b[3] * M(3, 4) / M(3, 3); M(4, 4) -= M(3, 4) * M(3, 4) / M(3, 3); M(4, 5) -= M(3, 5) * M(3, 4) / M(3, 3); M(4, 6) -= M(3, 6) * M(3, 4) / M(3, 3); M(4, 7) -= M(3, 7) * M(3, 4) / M(3, 3);
    b[5] -= b[3] * M(3, 5) / M(3, 3); M(5, 5) -= M(3, 5) * M(3, 5) / M(3, 3); M(5, 6) -= M(3, 6) * M(3, 5) / M(3, 3); M(5, 7) -= M(3, 7) * M(3, 5) / M(3, 3);
    b[6] -= b[3] * M(3, 6) / M(3, 3); M(6, 6) -= M(3, 6) * M(3, 6) / M(3, 3); M(6, 7) -= M(3, 7) * M(3, 6) / M(3, 3);
    b[7] -= b[3] * M(3, 7) / M(3, 3); M(7, 7) -= M(3, 7) * M(3, 7) / M(3, 3);

    b[5] -= b[4] * M(4, 5) / M(4, 4); M(5, 5) -= M(4, 5) * M(4, 5) / M(4, 4); M(5, 6) -= M(4, 6) * M(4, 5) / M(4, 4); M(5, 7) -= M(4, 7) * M(4, 5) / M(4, 4);
    b[6] -= b[4] * M(4, 6) / M(4, 4); M(6, 6) -= M(4, 6) * M(4, 6) / M(4, 4); M(6, 7) -= M(4, 7) * M(4, 6) / M(4, 4);
    b[7] -= b[4] * M(4, 7) / M(4, 4); M(7, 7) -= M(4, 7) * M(4, 7) / M(4, 4);

    b[6] -= b[5] * M(5, 6) / M(5, 5); M(6, 6) -= M(5, 6) * M(5, 6) / M(5, 5); M(6, 7) -= M(5, 7) * M(5, 6) / M(5, 5);
    b[7] -= b[5] * M(5, 7) / M(5, 5); M(7, 7) -= M(5, 7) * M(5, 7) / M(5, 5);

    b[7] -= b[6] * M(6, 7) / M(6, 6); M(7, 7) -= M(6, 7) * M(6, 7) / M(6, 6);

    b[7] /= M(7, 7);
    interp += b[7] * (X[7] - X[N]).zw;

    b[6] -= M(6, 7) * b[7]; b[6] /= M(6, 6);
    interp += b[6] * (X[6] - X[N]).zw;

    b[5] -= M(5, 6) * b[6]; b[5] -= M(5, 7) * b[7]; b[5] /= M(5, 5);
    interp += b[5] * (X[5] - X[N]).zw;

    b[4] -= M(4, 5) * b[5]; b[4] -= M(4, 6) * b[6]; b[4] -= M(4, 7) * b[7]; b[4] /= M(4, 4);
    interp += b[4] * (X[4] - X[N]).zw;

    b[3] -= M(3, 4) * b[4]; b[3] -= M(3, 5) * b[5]; b[3] -= M(3, 6) * b[6]; b[3] -= M(3, 7) * b[7]; b[3] /= M(3, 3);
    interp += b[3] * (X[3] - X[N]).zw;

    b[2] -= M(2, 3) * b[3]; b[2] -= M(2, 4) * b[4]; b[2] -= M(2, 5) * b[5]; b[2] -= M(2, 6) * b[6]; b[2] -= M(2, 7) * b[7]; b[2] /= M(2, 2);
    interp += b[2] * (X[2] - X[N]).zw;

    b[1] -= M(1, 2) * b[2]; b[1] -= M(1, 3) * b[3]; b[1] -= M(1, 4) * b[4]; b[1] -= M(1, 5) * b[5]; b[1] -= M(1, 6) * b[6]; b[1] -= M(1, 7) * b[7]; b[1] /= M(1, 1);
    interp += b[1] * (X[1] - X[N]).zw;

    b[0] -= M(0, 1) * b[1]; b[0] -= M(0, 2) * b[2]; b[0] -= M(0, 3) * b[3]; b[0] -= M(0, 4) * b[4]; b[0] -= M(0, 5) * b[5]; b[0] -= M(0, 6) * b[6]; b[0] -= M(0, 7) * b[7]; b[0] /= M(0, 0);
    interp += b[0] * (X[0] - X[N]).zw;

    return interp.xyxy;
}
