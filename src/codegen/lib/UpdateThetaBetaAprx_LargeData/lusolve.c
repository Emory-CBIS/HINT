/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * lusolve.c
 *
 * Code generation for function 'lusolve'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "lusolve.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"
#include "colon.h"

/* Function Definitions */
void lusolve(const emxArray_real32_T *A, const emxArray_real_T *B,
             emxArray_real32_T *X)
{
  emxArray_real32_T *b_A;
  int n;
  int k;
  int iy;
  emxArray_int32_T *ipiv;
  int nb;
  int u1;
  int j;
  int mmj;
  int c;
  int ix;
  float smax;
  int jA;
  int jy;
  int i;
  float s;
  emxInit_real32_T(&b_A, 2);
  n = A->size[1];
  k = b_A->size[0] * b_A->size[1];
  b_A->size[0] = A->size[0];
  b_A->size[1] = A->size[1];
  emxEnsureCapacity((emxArray__common *)b_A, k, sizeof(float));
  iy = A->size[0] * A->size[1];
  for (k = 0; k < iy; k++) {
    b_A->data[k] = A->data[k];
  }

  emxInit_int32_T1(&ipiv, 2);
  iy = A->size[1];
  eml_signed_integer_colon(iy, ipiv);
  if (!(A->size[1] < 1)) {
    iy = A->size[1] - 1;
    u1 = A->size[1];
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
          smax = (float)fabs(b_A->data[c]);
          for (k = 2; k <= mmj; k++) {
            ix++;
            s = (float)fabs(b_A->data[ix]);
            if (s > smax) {
              iy = k - 1;
              smax = s;
            }
          }
        }
      }

      if (b_A->data[c + iy] != 0.0F) {
        if (iy != 0) {
          ipiv->data[j] = (j + iy) + 1;
          ix = j;
          iy += j;
          for (k = 1; k <= n; k++) {
            smax = b_A->data[ix];
            b_A->data[ix] = b_A->data[iy];
            b_A->data[iy] = smax;
            ix += n;
            iy += n;
          }
        }

        k = c + mmj;
        for (i = c + 1; i + 1 <= k; i++) {
          b_A->data[i] /= b_A->data[c];
        }
      }

      iy = n - j;
      jA = (c + n) + 1;
      jy = c + n;
      for (i = 1; i < iy; i++) {
        smax = b_A->data[jy];
        if (b_A->data[jy] != 0.0F) {
          ix = c + 1;
          k = mmj + jA;
          for (nb = jA; nb + 1 < k; nb++) {
            b_A->data[nb] += b_A->data[ix] * -smax;
            ix++;
          }
        }

        jy += n;
        jA += n;
      }
    }
  }

  nb = B->size[0];
  k = X->size[0] * X->size[1];
  X->size[0] = B->size[0];
  X->size[1] = B->size[1];
  emxEnsureCapacity((emxArray__common *)X, k, sizeof(float));
  iy = B->size[0] * B->size[1];
  for (k = 0; k < iy; k++) {
    X->data[k] = (float)B->data[k];
  }

  if (A->size[1] != 0) {
    if (!((X->size[0] == 0) || (X->size[1] == 0))) {
      for (j = 0; j + 1 <= n; j++) {
        jA = nb * j - 1;
        jy = n * j;
        for (k = 1; k <= j; k++) {
          iy = nb * (k - 1);
          if (b_A->data[(k + jy) - 1] != 0.0F) {
            for (i = 1; i <= nb; i++) {
              X->data[i + jA] -= b_A->data[(k + jy) - 1] * X->data[(i + iy) - 1];
            }
          }
        }

        smax = b_A->data[j + jy];
        smax = 1.0F / smax;
        for (i = 1; i <= nb; i++) {
          X->data[i + jA] *= smax;
        }
      }
    }

    if (!((X->size[0] == 0) || (X->size[1] == 0))) {
      for (j = A->size[1]; j > 0; j--) {
        jA = nb * (j - 1) - 1;
        jy = n * (j - 1) - 1;
        for (k = j + 1; k <= n; k++) {
          iy = nb * (k - 1);
          if (b_A->data[k + jy] != 0.0F) {
            for (i = 1; i <= nb; i++) {
              X->data[i + jA] -= b_A->data[k + jy] * X->data[(i + iy) - 1];
            }
          }
        }
      }
    }
  }

  emxFree_real32_T(&b_A);
  for (iy = A->size[1] - 2; iy + 1 > 0; iy--) {
    if (ipiv->data[iy] != iy + 1) {
      jA = ipiv->data[iy] - 1;
      for (jy = 0; jy + 1 <= nb; jy++) {
        smax = X->data[jy + X->size[0] * iy];
        X->data[jy + X->size[0] * iy] = X->data[jy + X->size[0] * jA];
        X->data[jy + X->size[0] * jA] = smax;
      }
    }
  }

  emxFree_int32_T(&ipiv);
}

/* End of code generation (lusolve.c) */
