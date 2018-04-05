/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * diag.c
 *
 * Code generation for function 'diag'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "diag.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void b_diag(const float v[3600], float d[60])
{
  int j;
  for (j = 0; j < 60; j++) {
    d[j] = v[j * 61];
  }
}

void c_diag(const double v[3], double d[9])
{
  int j;
  memset(&d[0], 0, 9U * sizeof(double));
  for (j = 0; j < 3; j++) {
    d[j + 3 * j] = v[j];
  }
}

void d_diag(const emxArray_real_T *v, emxArray_real_T *d)
{
  int unnamed_idx_0;
  int unnamed_idx_1;
  int i5;
  unnamed_idx_0 = v->size[0];
  unnamed_idx_1 = v->size[0];
  i5 = d->size[0] * d->size[1];
  d->size[0] = unnamed_idx_0;
  d->size[1] = unnamed_idx_1;
  emxEnsureCapacity((emxArray__common *)d, i5, sizeof(double));
  unnamed_idx_0 *= unnamed_idx_1;
  for (i5 = 0; i5 < unnamed_idx_0; i5++) {
    d->data[i5] = 0.0;
  }

  for (unnamed_idx_0 = 0; unnamed_idx_0 + 1 <= v->size[0]; unnamed_idx_0++) {
    d->data[unnamed_idx_0 + d->size[0] * unnamed_idx_0] = v->data[unnamed_idx_0];
  }
}

void diag(const float v[60], float d[3600])
{
  int j;
  memset(&d[0], 0, 3600U * sizeof(float));
  for (j = 0; j < 60; j++) {
    d[j + 60 * j] = v[j];
  }
}

void e_diag(const emxArray_real_T *v, emxArray_real_T *d)
{
  int u0;
  int u1;
  int stride;
  if ((v->size[0] == 1) && (v->size[1] == 1)) {
    u0 = d->size[0];
    d->size[0] = 1;
    emxEnsureCapacity((emxArray__common *)d, u0, sizeof(double));
    d->data[0] = v->data[0];
  } else {
    if (0 < v->size[1]) {
      u0 = v->size[0];
      u1 = v->size[1];
      if (u0 < u1) {
        u1 = u0;
      }

      stride = v->size[0] + 1;
    } else {
      u1 = 0;
      stride = 0;
    }

    u0 = d->size[0];
    d->size[0] = u1;
    emxEnsureCapacity((emxArray__common *)d, u0, sizeof(double));
    for (u0 = 0; u0 + 1 <= u1; u0++) {
      d->data[u0] = v->data[u0 * stride];
    }
  }
}

/* End of code generation (diag.c) */
