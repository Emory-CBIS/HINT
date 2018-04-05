/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * inv.c
 *
 * Code generation for function 'inv'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "inv.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"
#include "colon.h"

/* Function Declarations */
static void invNxN(const emxArray_real_T *x, emxArray_real_T *y);

/* Function Definitions */
static void invNxN(const emxArray_real_T *x, emxArray_real_T *y)
{
  int n;
  int i13;
  int iy;
  emxArray_real_T *b_x;
  emxArray_int32_T *ipiv;
  emxArray_int32_T *p;
  int u1;
  int k;
  int j;
  int mmj;
  int c;
  int ix;
  double smax;
  int kAcol;
  int jy;
  double s;
  int ijA;
  n = x->size[0];
  i13 = y->size[0] * y->size[1];
  y->size[0] = x->size[0];
  y->size[1] = x->size[1];
  emxEnsureCapacity((emxArray__common *)y, i13, sizeof(double));
  iy = x->size[0] * x->size[1];
  for (i13 = 0; i13 < iy; i13++) {
    y->data[i13] = 0.0;
  }

  emxInit_real_T1(&b_x, 2);
  i13 = b_x->size[0] * b_x->size[1];
  b_x->size[0] = x->size[0];
  b_x->size[1] = x->size[1];
  emxEnsureCapacity((emxArray__common *)b_x, i13, sizeof(double));
  iy = x->size[0] * x->size[1];
  for (i13 = 0; i13 < iy; i13++) {
    b_x->data[i13] = x->data[i13];
  }

  emxInit_int32_T1(&ipiv, 2);
  iy = x->size[0];
  eml_signed_integer_colon(iy, ipiv);
  if (!(x->size[0] < 1)) {
    iy = x->size[0] - 1;
    u1 = x->size[0];
    if (iy < u1) {
      u1 = iy;
    }

    for (j = 0; j + 1 <= u1; j++) {
      mmj = n - j;
      c = j * (n + 1);
      if (mmj < 1) {
        iy = -1;
      } else {
        iy = 0;
        if (mmj > 1) {
          ix = c;
          smax = fabs(b_x->data[c]);
          for (k = 2; k <= mmj; k++) {
            ix++;
            s = fabs(b_x->data[ix]);
            if (s > smax) {
              iy = k - 1;
              smax = s;
            }
          }
        }
      }

      if (b_x->data[c + iy] != 0.0) {
        if (iy != 0) {
          ipiv->data[j] = (j + iy) + 1;
          ix = j;
          iy += j;
          for (k = 1; k <= n; k++) {
            smax = b_x->data[ix];
            b_x->data[ix] = b_x->data[iy];
            b_x->data[iy] = smax;
            ix += n;
            iy += n;
          }
        }

        i13 = c + mmj;
        for (jy = c + 1; jy + 1 <= i13; jy++) {
          b_x->data[jy] /= b_x->data[c];
        }
      }

      kAcol = n - j;
      iy = (c + n) + 1;
      jy = c + n;
      for (k = 1; k < kAcol; k++) {
        smax = b_x->data[jy];
        if (b_x->data[jy] != 0.0) {
          ix = c + 1;
          i13 = mmj + iy;
          for (ijA = iy; ijA + 1 < i13; ijA++) {
            b_x->data[ijA] += b_x->data[ix] * -smax;
            ix++;
          }
        }

        jy += n;
        iy += n;
      }
    }
  }

  emxInit_int32_T1(&p, 2);
  eml_signed_integer_colon(x->size[0], p);
  for (k = 0; k < ipiv->size[1]; k++) {
    if (ipiv->data[k] > 1 + k) {
      iy = p->data[ipiv->data[k] - 1];
      p->data[ipiv->data[k] - 1] = p->data[k];
      p->data[k] = iy;
    }
  }

  emxFree_int32_T(&ipiv);
  for (k = 0; k + 1 <= n; k++) {
    c = p->data[k] - 1;
    y->data[k + y->size[0] * (p->data[k] - 1)] = 1.0;
    for (j = k; j + 1 <= n; j++) {
      if (y->data[j + y->size[0] * c] != 0.0) {
        for (jy = j + 1; jy + 1 <= n; jy++) {
          y->data[jy + y->size[0] * c] -= y->data[j + y->size[0] * c] *
            b_x->data[jy + b_x->size[0] * j];
        }
      }
    }
  }

  emxFree_int32_T(&p);
  if ((x->size[0] != 0) && (!((y->size[0] == 0) || (y->size[1] == 0)))) {
    for (j = 1; j <= n; j++) {
      iy = n * (j - 1) - 1;
      for (k = n; k > 0; k--) {
        kAcol = n * (k - 1) - 1;
        if (y->data[k + iy] != 0.0) {
          smax = y->data[k + iy];
          s = b_x->data[k + kAcol];
          y->data[k + iy] = smax / s;
          for (jy = 1; jy < k; jy++) {
            y->data[jy + iy] -= y->data[k + iy] * b_x->data[jy + kAcol];
          }
        }
      }
    }
  }

  emxFree_real_T(&b_x);
}

void inv(const emxArray_real_T *x, emxArray_real_T *y)
{
  int i12;
  int loop_ub;
  if ((x->size[0] == 0) || (x->size[1] == 0)) {
    i12 = y->size[0] * y->size[1];
    y->size[0] = x->size[0];
    y->size[1] = x->size[1];
    emxEnsureCapacity((emxArray__common *)y, i12, sizeof(double));
    loop_ub = x->size[0] * x->size[1];
    for (i12 = 0; i12 < loop_ub; i12++) {
      y->data[i12] = x->data[i12];
    }
  } else {
    invNxN(x, y);
  }
}

/* End of code generation (inv.c) */
