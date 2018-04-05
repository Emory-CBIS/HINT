/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * UpdateThetaBetaAprx_LargeData.c
 *
 * Code generation for function 'UpdateThetaBetaAprx_LargeData'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"
#include "G_zv_gen.h"
#include "sum.h"
#include "log.h"
#include "normpdf.h"
#include "sqrt.h"
#include "diag.h"
#include "blkdiag.h"
#include "permute.h"
#include "squeeze.h"
#include "mrdivide.h"
#include "eye.h"
#include "rdivide.h"
#include "kron.h"
#include "mean.h"
#include "sqrtm.h"
#include "inv.h"
#include "trace.h"
#include "power.h"

/* Function Definitions */
void UpdateThetaBetaAprx_LargeData(const double Y[304800], const double X_mtx[40],
  const struct0_T *theta, const float C_matrix_diag[60], const double beta[30480],
  double N, double T, double q, double p, double m, double V, struct1_T
  *theta_new, emxArray_real_T *beta_new, emxArray_real_T *z_mode,
  emxArray_real_T *subICmean, emxArray_real_T *subICvar, emxArray_real_T
  *grpICmean, emxArray_real_T *grpICvar, double *err, emxArray_real_T *G_z_dict)
{
  int i0;
  int loop_ub;
  emxArray_real_T *A_ProdPart1;
  emxArray_real_T *A_ProdPart2;
  emxArray_real_T *sigma2_sq_all_V;
  emxArray_real_T *G_z;
  double varargin_1;
  emxArray_real_T *sumXiXiT_inv;
  int n;
  emxArray_real_T *A;
  double b_X_mtx[4];
  int i1;
  emxArray_real_T *C_inv;
  int i;
  emxArray_int32_T *r0;
  emxArray_int32_T *ii;
  emxArray_real_T *r1;
  double y;
  emxArray_real_T *B;
  int nx;
  boolean_T empty_non_axis_sizes;
  int idx;
  double b_theta[9];
  int br;
  double b_y;
  emxArray_real_T *W2;
  emxArray_real_T *Sigma23z;
  emxArray_real_T *z_dict;
  cell_wrap_0 reshapes[2];
  emxArray_real_T *P;
  float b_C_matrix_diag[60];
  float Sigma1[3600];
  emxArray_real_T *Sigma2;
  float fv0[60];
  emxArray_real32_T *b_W2;
  float Sigma1_inv[3600];
  double dv0[9];
  emxArray_real32_T *Sigma_gamma0;
  emxArray_real_T *nanid;
  emxArray_real_T *b_z_dict;
  emxArray_real_T *r2;
  emxArray_real_T *VoxelIC;
  int v;
  emxArray_real_T *Beta_v_trans;
  emxArray_real_T *Probzv;
  emxArray_real_T *miu3z;
  emxArray_real_T *miu_temp;
  emxArray_real32_T *Sigma_gamma;
  emxArray_real32_T *miu_star;
  emxArray_real32_T *miu_sv_svT_all;
  emxArray_real_T *miu_svi;
  emxArray_real_T *miu_svi_sviT;
  emxArray_real_T *miu_svi_svT;
  emxArray_real32_T *miu_sv;
  emxArray_real32_T *miu_sv_svT;
  emxArray_real_T *mtSum;
  emxArray_real_T *miu_svi_trans;
  emxArray_real_T *nois;
  emxArray_real_T *c_y;
  emxArray_real_T *C;
  emxArray_real32_T *d_y;
  emxArray_real_T *e_y;
  emxArray_real_T *r3;
  emxArray_real32_T *b_Sigma_gamma0;
  emxArray_real_T *b_miu_temp;
  emxArray_real_T *b_C;
  emxArray_real32_T *f_y;
  emxArray_real32_T *b_P;
  emxArray_real32_T *c_miu_temp;
  emxArray_real32_T *c_P;
  emxArray_real32_T *b_miu_star;
  emxArray_real32_T *d_P;
  emxArray_real32_T *r4;
  emxArray_real32_T *r5;
  emxArray_real32_T *b_beta_new;
  emxArray_real_T *b_sigma2_sq_all_V;
  emxArray_real32_T *b_miu_svi;
  emxArray_real_T *c_beta_new;
  emxArray_real_T *b_Y;
  emxArray_real_T *b_miu_svi_trans;
  double b_beta[6];
  boolean_T exitg1;
  int k;
  unsigned int unnamed_idx_1;
  int b_m;
  int ic;
  int ar;
  int ia;
  emxArray_boolean_T *b;
  emxArray_real_T *b_grpICvar;
  emxArray_real_T *c_grpICvar;
  emxArray_real_T *b_grpICmean;
  emxArray_real_T *c_grpICmean;
  unsigned int unnamed_idx_0;
  emxArray_creal_T *r6;
  emxArray_real_T *b_A_ProdPart2;
  float c_z_dict[3600];
  emxArray_real_T *g_y;
  emxArray_real_T *a;
  emxArray_real_T *b_C_inv;
  emxArray_real_T *c_C_inv;
  emxArray_real_T *d_C_inv;
  int i2;
  int i3;
  boolean_T guard1 = false;
  double y_data[60];
  double c_Y[60];
  float f0;

  /* [theta_new, beta_new] = UpdateThetaBeta (Y, X_mtx, theta, beta, N, T, q, p, m, V) */
  /*  After preprocessing, T=q */
  /*  Y           :  Y(:,V)  individual i scan time T at voxel v,      TN*V */
  /*  X_mtx       :  X(i,k)  predictor k for individual i,             p*N */
  /*  beta        :  beta (k, l, v)  coefficients at voxel v,          p*q*V */
  /*  C_matrix_diag: diagnal elements of C_matrix; % C matrix is (q * N)x1 */
  /*  miu_svi     :  E(si(v) | Y(v), theta)                            q*1*N */
  /*  miu_sv      :  E(s(v)  | Y(v), theta)                            q*1 */
  /*  miu_svi_sviT:  E(si(v)si(v)'| Y(v), theta)                       q*q*N */
  /*  miu_sv_svT  :  E(s(v)s(v)'  | Y(v), theta)                       q*q */
  /*  miu_sv_sviT :  E(s(v)si(v)' | Y(v), theta)                       q*q*N */
  /*  First calculate the conditional probability of ICs given the data and */
  /*  latent sorce state */
  i0 = theta_new->A->size[0] * theta_new->A->size[1] * theta_new->A->size[2];
  theta_new->A->size[0] = (int)T;
  theta_new->A->size[1] = (int)q;
  theta_new->A->size[2] = (int)N;
  emxEnsureCapacity((emxArray__common *)theta_new->A, i0, sizeof(double));
  loop_ub = (int)T * (int)q * (int)N;
  for (i0 = 0; i0 < loop_ub; i0++) {
    theta_new->A->data[i0] = 0.0;
  }

  theta_new->sigma1_sq = 0.0;
  i0 = theta_new->miu3->size[0];
  theta_new->miu3->size[0] = (int)(m * q);
  emxEnsureCapacity((emxArray__common *)theta_new->miu3, i0, sizeof(double));
  loop_ub = (int)(m * q);
  for (i0 = 0; i0 < loop_ub; i0++) {
    theta_new->miu3->data[i0] = 0.0;
  }

  /* pi, miu3, sigma3 in the order of miul1,...,miulm, l=1:q */
  i0 = theta_new->sigma3_sq->size[0];
  theta_new->sigma3_sq->size[0] = (int)(m * q);
  emxEnsureCapacity((emxArray__common *)theta_new->sigma3_sq, i0, sizeof(double));
  loop_ub = (int)(m * q);
  for (i0 = 0; i0 < loop_ub; i0++) {
    theta_new->sigma3_sq->data[i0] = 0.0;
  }

  i0 = theta_new->pi->size[0];
  theta_new->pi->size[0] = (int)(m * q);
  emxEnsureCapacity((emxArray__common *)theta_new->pi, i0, sizeof(double));
  loop_ub = (int)(m * q);
  for (i0 = 0; i0 < loop_ub; i0++) {
    theta_new->pi->data[i0] = 0.0;
  }

  i0 = beta_new->size[0] * beta_new->size[1] * beta_new->size[2];
  beta_new->size[0] = (int)p;
  beta_new->size[1] = (int)q;
  beta_new->size[2] = (int)V;
  emxEnsureCapacity((emxArray__common *)beta_new, i0, sizeof(double));
  loop_ub = (int)p * (int)q * (int)V;
  for (i0 = 0; i0 < loop_ub; i0++) {
    beta_new->data[i0] = 0.0;
  }

  emxInit_real_T(&A_ProdPart1, 3);
  i0 = A_ProdPart1->size[0] * A_ProdPart1->size[1] * A_ProdPart1->size[2];
  A_ProdPart1->size[0] = (int)T;
  A_ProdPart1->size[1] = (int)q;
  A_ProdPart1->size[2] = (int)N;
  emxEnsureCapacity((emxArray__common *)A_ProdPart1, i0, sizeof(double));
  loop_ub = (int)T * (int)q * (int)N;
  for (i0 = 0; i0 < loop_ub; i0++) {
    A_ProdPart1->data[i0] = 0.0;
  }

  emxInit_real_T(&A_ProdPart2, 3);

  /* first part of the product format for Ai */
  i0 = A_ProdPart2->size[0] * A_ProdPart2->size[1] * A_ProdPart2->size[2];
  A_ProdPart2->size[0] = (int)q;
  A_ProdPart2->size[1] = (int)q;
  A_ProdPart2->size[2] = (int)N;
  emxEnsureCapacity((emxArray__common *)A_ProdPart2, i0, sizeof(double));
  loop_ub = (int)q * (int)q * (int)N;
  for (i0 = 0; i0 < loop_ub; i0++) {
    A_ProdPart2->data[i0] = 0.0;
  }

  emxInit_real_T(&sigma2_sq_all_V, 3);

  /* second part of the product format for Ai */
  /* sigma2_sq_all       = zeros(q, q);     %%% record all second level variance-covariance */
  i0 = sigma2_sq_all_V->size[0] * sigma2_sq_all_V->size[1] *
    sigma2_sq_all_V->size[2];
  sigma2_sq_all_V->size[0] = (int)q;
  sigma2_sq_all_V->size[1] = (int)q;
  sigma2_sq_all_V->size[2] = (int)V;
  emxEnsureCapacity((emxArray__common *)sigma2_sq_all_V, i0, sizeof(double));
  loop_ub = (int)q * (int)q * (int)V;
  for (i0 = 0; i0 < loop_ub; i0++) {
    sigma2_sq_all_V->data[i0] = 0.0;
  }

  emxInit_real_T1(&G_z, 2);
  varargin_1 = N * p;

  /* reshape by column */
  eye(p, G_z);
  for (i0 = 0; i0 < 2; i0++) {
    for (n = 0; n < 2; n++) {
      b_X_mtx[i0 + (n << 1)] = 0.0;
      for (i1 = 0; i1 < 20; i1++) {
        b_X_mtx[i0 + (n << 1)] += X_mtx[i0 + (i1 << 1)] * X_mtx[n + (i1 << 1)];
      }
    }
  }

  emxInit_real_T1(&sumXiXiT_inv, 2);
  emxInit_real_T1(&A, 2);
  mrdivide(G_z, b_X_mtx, sumXiXiT_inv);
  i0 = A->size[0] * A->size[1];
  A->size[0] = (int)(N * T);
  A->size[1] = (int)(N * q);
  emxEnsureCapacity((emxArray__common *)A, i0, sizeof(double));
  loop_ub = (int)(N * T) * (int)(N * q);
  for (i0 = 0; i0 < loop_ub; i0++) {
    A->data[i0] = 0.0;
  }

  emxInit_real_T1(&C_inv, 2);
  i0 = C_inv->size[0] * C_inv->size[1];
  C_inv->size[0] = (int)T;
  C_inv->size[1] = (int)N;
  emxEnsureCapacity((emxArray__common *)C_inv, i0, sizeof(double));
  i = 0;
  emxInit_int32_T(&r0, 1);
  emxInit_int32_T(&ii, 1);
  while (i <= (int)N - 1) {
    y = ((1.0 + (double)i) - 1.0) * T;
    i0 = ii->size[0];
    ii->size[0] = (int)floor(T - 1.0) + 1;
    emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
    loop_ub = (int)floor(T - 1.0);
    for (i0 = 0; i0 <= loop_ub; i0++) {
      ii->data[i0] = (int)(y + (1.0 + (double)i0)) - 1;
    }

    y = ((1.0 + (double)i) - 1.0) * q;
    i0 = r0->size[0];
    r0->size[0] = (int)floor(q - 1.0) + 1;
    emxEnsureCapacity((emxArray__common *)r0, i0, sizeof(int));
    loop_ub = (int)floor(q - 1.0);
    for (i0 = 0; i0 <= loop_ub; i0++) {
      r0->data[i0] = (int)(y + (1.0 + (double)i0)) - 1;
    }

    for (i0 = 0; i0 < 3; i0++) {
      for (n = 0; n < 3; n++) {
        b_theta[n + 3 * i0] = theta->A[(n + 3 * i0) + 9 * i];
      }
    }

    nx = ii->size[0];
    idx = r0->size[0];
    for (i0 = 0; i0 < idx; i0++) {
      for (n = 0; n < nx; n++) {
        A->data[ii->data[n] + A->size[0] * r0->data[i0]] = b_theta[n + nx * i0];
      }
    }

    y = (T * (1.0 + (double)i) - T) + 1.0;
    b_y = T * (1.0 + (double)i);
    if (y > b_y) {
      i0 = 1;
      n = 0;
    } else {
      i0 = (int)y;
      n = (int)b_y;
    }

    loop_ub = n - i0;
    for (n = 0; n <= loop_ub; n++) {
      C_inv->data[n + C_inv->size[0] * i] = 1.0F / C_matrix_diag[(i0 + n) - 1];
    }

    i++;
  }

  emxInit_real_T2(&r1, 1);
  eye(q, G_z);
  i0 = r1->size[0];
  r1->size[0] = (int)N;
  emxEnsureCapacity((emxArray__common *)r1, i0, sizeof(double));
  loop_ub = (int)N;
  for (i0 = 0; i0 < loop_ub; i0++) {
    r1->data[i0] = 1.0;
  }

  emxInit_real_T1(&B, 2);
  kron(r1, G_z, B);

  /* W2  =   [A, A*B]; */
  eye(N * q, G_z);
  emxFree_real_T(&r1);
  if (!((G_z->size[0] == 0) || (G_z->size[1] == 0))) {
    nx = G_z->size[0];
  } else if (!((B->size[0] == 0) || (B->size[1] == 0))) {
    nx = B->size[0];
  } else {
    nx = G_z->size[0];
    if (!(nx > 0)) {
      nx = 0;
    }

    if (B->size[0] > nx) {
      nx = B->size[0];
    }
  }

  empty_non_axis_sizes = (nx == 0);
  if (empty_non_axis_sizes || (!((G_z->size[0] == 0) || (G_z->size[1] == 0)))) {
    idx = G_z->size[1];
  } else {
    idx = 0;
  }

  if (empty_non_axis_sizes || (!((B->size[0] == 0) || (B->size[1] == 0)))) {
    br = B->size[1];
  } else {
    br = 0;
  }

  emxInit_real_T1(&W2, 2);
  i0 = W2->size[0] * W2->size[1];
  W2->size[0] = nx;
  W2->size[1] = idx + br;
  emxEnsureCapacity((emxArray__common *)W2, i0, sizeof(double));
  for (i0 = 0; i0 < idx; i0++) {
    for (n = 0; n < nx; n++) {
      W2->data[n + W2->size[0] * i0] = G_z->data[n + nx * i0];
    }
  }

  for (i0 = 0; i0 < br; i0++) {
    for (n = 0; n < nx; n++) {
      W2->data[n + W2->size[0] * (i0 + idx)] = B->data[n + nx * i0];
    }
  }

  emxInit_real_T1(&Sigma23z, 2);
  eye(N * q, G_z);
  if (!((G_z->size[0] == 0) || (G_z->size[1] == 0))) {
    nx = G_z->size[0];
  } else if (!((B->size[0] == 0) || (B->size[1] == 0))) {
    nx = B->size[0];
  } else {
    nx = G_z->size[0];
    if (!(nx > 0)) {
      nx = 0;
    }

    if (B->size[0] > nx) {
      nx = B->size[0];
    }
  }

  empty_non_axis_sizes = (nx == 0);
  if (empty_non_axis_sizes || (!((G_z->size[0] == 0) || (G_z->size[1] == 0)))) {
    idx = G_z->size[1];
  } else {
    idx = 0;
  }

  if (empty_non_axis_sizes || (!((B->size[0] == 0) || (B->size[1] == 0)))) {
    br = B->size[1];
  } else {
    br = 0;
  }

  i0 = Sigma23z->size[0] * Sigma23z->size[1];
  Sigma23z->size[0] = nx;
  Sigma23z->size[1] = idx + br;
  emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
  for (i0 = 0; i0 < idx; i0++) {
    for (n = 0; n < nx; n++) {
      Sigma23z->data[n + Sigma23z->size[0] * i0] = G_z->data[n + nx * i0];
    }
  }

  for (i0 = 0; i0 < br; i0++) {
    for (n = 0; n < nx; n++) {
      Sigma23z->data[n + Sigma23z->size[0] * (i0 + idx)] = B->data[n + nx * i0];
    }
  }

  emxInit_real_T1(&z_dict, 2);
  eye(q, z_dict);
  if (!(((int)q == 0) || ((int)(N * q) == 0))) {
    nx = (int)q;
  } else if (!((z_dict->size[0] == 0) || (z_dict->size[1] == 0))) {
    nx = z_dict->size[0];
  } else {
    nx = (int)q;
    if (!(nx > 0)) {
      nx = 0;
    }

    if (z_dict->size[0] > nx) {
      nx = z_dict->size[0];
    }
  }

  empty_non_axis_sizes = (nx == 0);
  if (empty_non_axis_sizes || (!(((int)q == 0) || ((int)(N * q) == 0)))) {
    idx = (int)(N * q);
  } else {
    idx = 0;
  }

  emxInitMatrix_cell_wrap_0(reshapes);
  i0 = reshapes[0].f1->size[0] * reshapes[0].f1->size[1];
  reshapes[0].f1->size[0] = nx;
  reshapes[0].f1->size[1] = idx;
  emxEnsureCapacity((emxArray__common *)reshapes[0].f1, i0, sizeof(double));
  loop_ub = nx * idx;
  for (i0 = 0; i0 < loop_ub; i0++) {
    reshapes[0].f1->data[i0] = 0.0;
  }

  if (empty_non_axis_sizes || (!((z_dict->size[0] == 0) || (z_dict->size[1] == 0))))
  {
    idx = z_dict->size[1];
  } else {
    idx = 0;
  }

  i0 = G_z->size[0] * G_z->size[1];
  G_z->size[0] = reshapes[0].f1->size[0];
  G_z->size[1] = reshapes[0].f1->size[1] + idx;
  emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
  loop_ub = reshapes[0].f1->size[1];
  for (i0 = 0; i0 < loop_ub; i0++) {
    br = reshapes[0].f1->size[0];
    for (n = 0; n < br; n++) {
      G_z->data[n + G_z->size[0] * i0] = reshapes[0].f1->data[n + reshapes[0].
        f1->size[0] * i0];
    }
  }

  for (i0 = 0; i0 < idx; i0++) {
    for (n = 0; n < nx; n++) {
      G_z->data[n + G_z->size[0] * (i0 + reshapes[0].f1->size[1])] =
        z_dict->data[n + nx * i0];
    }
  }

  emxFreeMatrix_cell_wrap_0(reshapes);
  if (!((Sigma23z->size[0] == 0) || (Sigma23z->size[1] == 0))) {
    nx = Sigma23z->size[1];
  } else if (!((G_z->size[0] == 0) || (G_z->size[1] == 0))) {
    nx = G_z->size[1];
  } else {
    nx = Sigma23z->size[1];
    if (!(nx > 0)) {
      nx = 0;
    }

    if (G_z->size[1] > nx) {
      nx = G_z->size[1];
    }
  }

  empty_non_axis_sizes = (nx == 0);
  if (empty_non_axis_sizes || (!((Sigma23z->size[0] == 0) || (Sigma23z->size[1] ==
         0)))) {
    idx = Sigma23z->size[0];
  } else {
    idx = 0;
  }

  if (empty_non_axis_sizes || (!((G_z->size[0] == 0) || (G_z->size[1] == 0)))) {
    br = G_z->size[0];
  } else {
    br = 0;
  }

  emxInit_real_T1(&P, 2);
  i0 = P->size[0] * P->size[1];
  P->size[0] = idx + br;
  P->size[1] = nx;
  emxEnsureCapacity((emxArray__common *)P, i0, sizeof(double));
  for (i0 = 0; i0 < nx; i0++) {
    for (n = 0; n < idx; n++) {
      P->data[n + P->size[0] * i0] = Sigma23z->data[n + idx * i0];
    }
  }

  for (i0 = 0; i0 < nx; i0++) {
    for (n = 0; n < br; n++) {
      P->data[(n + idx) + P->size[0] * i0] = G_z->data[n + br * i0];
    }
  }

  for (i = 0; i < 60; i++) {
    b_C_matrix_diag[i] = C_matrix_diag[i] * (float)theta->sigma1_sq;
  }

  diag(b_C_matrix_diag, Sigma1);
  b_diag(Sigma1, b_C_matrix_diag);
  for (i = 0; i < 60; i++) {
    fv0[i] = 1.0F / b_C_matrix_diag[i];
  }

  emxInit_real_T1(&Sigma2, 2);
  emxInit_real32_T(&b_W2, 2);
  diag(fv0, Sigma1_inv);
  eye(N, G_z);
  c_diag(theta->sigma2_sq, dv0);
  b_kron(G_z, dv0, Sigma2);
  i0 = b_W2->size[0] * b_W2->size[1];
  b_W2->size[0] = W2->size[1];
  b_W2->size[1] = 60;
  emxEnsureCapacity((emxArray__common *)b_W2, i0, sizeof(float));
  loop_ub = W2->size[1];
  for (i0 = 0; i0 < loop_ub; i0++) {
    for (n = 0; n < 60; n++) {
      b_W2->data[i0 + b_W2->size[0] * n] = 0.0F;
      br = W2->size[0];
      for (i1 = 0; i1 < br; i1++) {
        b_W2->data[i0 + b_W2->size[0] * n] += (float)W2->data[i1 + W2->size[0] *
          i0] * Sigma1_inv[i1 + 60 * n];
      }
    }
  }

  emxInit_real32_T(&Sigma_gamma0, 2);
  i0 = Sigma_gamma0->size[0] * Sigma_gamma0->size[1];
  Sigma_gamma0->size[0] = b_W2->size[0];
  Sigma_gamma0->size[1] = W2->size[1];
  emxEnsureCapacity((emxArray__common *)Sigma_gamma0, i0, sizeof(float));
  loop_ub = b_W2->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    br = W2->size[1];
    for (n = 0; n < br; n++) {
      Sigma_gamma0->data[i0 + Sigma_gamma0->size[0] * n] = 0.0F;
      for (i1 = 0; i1 < 60; i1++) {
        Sigma_gamma0->data[i0 + Sigma_gamma0->size[0] * n] += b_W2->data[i0 +
          b_W2->size[0] * i1] * (float)W2->data[i1 + W2->size[0] * n];
      }
    }
  }

  emxFree_real32_T(&b_W2);
  emxInit_real_T2(&nanid, 1);

  /* %%%% dictionary for the z(v) s */
  eye(q, G_z);
  i0 = nanid->size[0];
  nanid->size[0] = (int)q;
  emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
  loop_ub = (int)q;
  for (i0 = 0; i0 < loop_ub; i0++) {
    nanid->data[i0] = 2.0;
  }

  i0 = G_z->size[0] * G_z->size[1];
  G_z->size[0] = (int)q;
  G_z->size[1] = (int)q;
  emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
  loop_ub = (int)q * (int)q;
  for (i0 = 0; i0 < loop_ub; i0++) {
    G_z->data[i0] = 2.0 - G_z->data[i0];
  }

  if (!((G_z->size[0] == 0) || (G_z->size[1] == 0))) {
    nx = G_z->size[0];
  } else if (!(nanid->size[0] == 0)) {
    nx = nanid->size[0];
  } else {
    nx = G_z->size[0];
    if (!(nx > 0)) {
      nx = 0;
    }
  }

  empty_non_axis_sizes = (nx == 0);
  if (empty_non_axis_sizes || (!((G_z->size[0] == 0) || (G_z->size[1] == 0)))) {
    idx = G_z->size[1];
  } else {
    idx = 0;
  }

  if (empty_non_axis_sizes || (!(nanid->size[0] == 0))) {
    br = 1;
  } else {
    br = 0;
  }

  i0 = z_dict->size[0] * z_dict->size[1];
  z_dict->size[0] = nx;
  z_dict->size[1] = idx + br;
  emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
  for (i0 = 0; i0 < idx; i0++) {
    for (n = 0; n < nx; n++) {
      z_dict->data[n + z_dict->size[0] * i0] = G_z->data[n + nx * i0];
    }
  }

  for (i0 = 0; i0 < br; i0++) {
    for (n = 0; n < nx; n++) {
      z_dict->data[n + z_dict->size[0] * (i0 + idx)] = nanid->data[n + nx * i0];
    }
  }

  i0 = G_z_dict->size[0] * G_z_dict->size[1] * G_z_dict->size[2];
  G_z_dict->size[0] = (int)q;
  G_z_dict->size[1] = (int)(m * q);
  G_z_dict->size[2] = (int)(q + 1.0);
  emxEnsureCapacity((emxArray__common *)G_z_dict, i0, sizeof(double));
  loop_ub = (int)q * (int)(m * q) * (int)(q + 1.0);
  for (i0 = 0; i0 < loop_ub; i0++) {
    G_z_dict->data[i0] = 0.0;
  }

  i = 0;
  emxInit_real_T2(&b_z_dict, 1);
  emxInit_real_T1(&r2, 2);
  while (i <= (int)(q + 1.0) - 1) {
    loop_ub = z_dict->size[0];
    i0 = b_z_dict->size[0];
    b_z_dict->size[0] = loop_ub;
    emxEnsureCapacity((emxArray__common *)b_z_dict, i0, sizeof(double));
    for (i0 = 0; i0 < loop_ub; i0++) {
      b_z_dict->data[i0] = z_dict->data[i0 + z_dict->size[0] * i];
    }

    G_zv_gen(b_z_dict, m, q, r2);
    loop_ub = r2->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = r2->size[0];
      for (n = 0; n < br; n++) {
        G_z_dict->data[(n + G_z_dict->size[0] * i0) + G_z_dict->size[0] *
          G_z_dict->size[1] * i] = r2->data[n + r2->size[0] * i0];
      }
    }

    i++;
  }

  emxFree_real_T(&r2);
  emxFree_real_T(&b_z_dict);
  emxInit_real_T2(&VoxelIC, 1);

  /* %% Main V loop */
  i0 = VoxelIC->size[0];
  VoxelIC->size[0] = (int)V;
  emxEnsureCapacity((emxArray__common *)VoxelIC, i0, sizeof(double));
  i0 = z_mode->size[0];
  z_mode->size[0] = (int)V;
  emxEnsureCapacity((emxArray__common *)z_mode, i0, sizeof(double));
  i0 = subICmean->size[0] * subICmean->size[1] * subICmean->size[2];
  subICmean->size[0] = (int)q;
  subICmean->size[1] = (int)N;
  subICmean->size[2] = (int)V;
  emxEnsureCapacity((emxArray__common *)subICmean, i0, sizeof(double));
  i0 = subICvar->size[0] * subICvar->size[1] * subICvar->size[2] *
    subICvar->size[3];
  subICvar->size[0] = (int)q;
  subICvar->size[1] = (int)q;
  subICvar->size[2] = (int)N;
  subICvar->size[3] = (int)V;
  emxEnsureCapacity((emxArray__common *)subICvar, i0, sizeof(double));
  i0 = grpICmean->size[0] * grpICmean->size[1];
  grpICmean->size[0] = (int)q;
  grpICmean->size[1] = (int)V;
  emxEnsureCapacity((emxArray__common *)grpICmean, i0, sizeof(double));
  i0 = grpICvar->size[0] * grpICvar->size[1] * grpICvar->size[2];
  grpICvar->size[0] = (int)q;
  grpICvar->size[1] = (int)q;
  grpICvar->size[2] = (int)V;
  emxEnsureCapacity((emxArray__common *)grpICvar, i0, sizeof(double));
  v = 0;
  emxInit_real_T1(&Beta_v_trans, 2);
  emxInit_real_T2(&Probzv, 1);
  emxInit_real_T2(&miu3z, 1);
  emxInit_real_T2(&miu_temp, 1);
  emxInit_real32_T(&Sigma_gamma, 2);
  emxInit_real32_T1(&miu_star, 1);
  emxInit_real32_T(&miu_sv_svT_all, 2);
  emxInit_real_T(&miu_svi, 3);
  emxInit_real_T(&miu_svi_sviT, 3);
  emxInit_real_T(&miu_svi_svT, 3);
  emxInit_real32_T1(&miu_sv, 1);
  emxInit_real32_T(&miu_sv_svT, 2);
  emxInit_real_T(&mtSum, 3);
  emxInit_real_T(&miu_svi_trans, 3);
  emxInit_real_T2(&nois, 1);
  emxInit_real_T1(&c_y, 2);
  emxInit_real_T2(&C, 1);
  emxInit_real32_T(&d_y, 2);
  emxInit_real_T1(&e_y, 2);
  emxInit_real_T1(&r3, 2);
  emxInit_real32_T(&b_Sigma_gamma0, 2);
  emxInit_real_T2(&b_miu_temp, 1);
  emxInit_real_T2(&b_C, 1);
  emxInit_real32_T1(&f_y, 1);
  emxInit_real32_T1(&b_P, 1);
  emxInit_real32_T1(&c_miu_temp, 1);
  emxInit_real32_T(&c_P, 2);
  emxInit_real32_T(&b_miu_star, 2);
  emxInit_real32_T(&d_P, 2);
  emxInit_real32_T1(&r4, 1);
  emxInit_real32_T(&r5, 2);
  emxInit_real32_T(&b_beta_new, 2);
  emxInit_real_T1(&b_sigma2_sq_all_V, 2);
  emxInit_real32_T(&b_miu_svi, 2);
  emxInit_real_T1(&c_beta_new, 2);
  emxInit_real_T2(&b_Y, 1);
  emxInit_real_T1(&b_miu_svi_trans, 2);
  while (v <= (int)V - 1) {
    /*  E-Step: generating all moments for updating */
    eye(N, G_z);
    for (i0 = 0; i0 < 2; i0++) {
      for (n = 0; n < 3; n++) {
        b_beta[n + 3 * i0] = beta[(i0 + (n << 1)) + 6 * v];
      }
    }

    c_kron(G_z, b_beta, Beta_v_trans);
    i0 = Probzv->size[0];
    Probzv->size[0] = (int)(q + 1.0);
    emxEnsureCapacity((emxArray__common *)Probzv, i0, sizeof(double));
    loop_ub = (int)(q + 1.0);
    for (i0 = 0; i0 < loop_ub; i0++) {
      Probzv->data[i0] = 0.0;
    }

    /*  Save moments conditional on z_r */
    for (i = 0; i < (int)(q + 1.0); i++) {
      /*  Get the Z configuration */
      loop_ub = G_z_dict->size[0];
      br = G_z_dict->size[1];
      i0 = G_z->size[0] * G_z->size[1];
      G_z->size[0] = loop_ub;
      G_z->size[1] = br;
      emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
      for (i0 = 0; i0 < br; i0++) {
        for (n = 0; n < loop_ub; n++) {
          G_z->data[n + G_z->size[0] * i0] = G_z_dict->data[(n + G_z_dict->size
            [0] * i0) + G_z_dict->size[0] * G_z_dict->size[1] * i];
        }
      }

      i0 = G_z_dict->size[1];
      if (i0 == 1) {
        i0 = miu3z->size[0];
        miu3z->size[0] = G_z->size[0];
        emxEnsureCapacity((emxArray__common *)miu3z, i0, sizeof(double));
        loop_ub = G_z->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          miu3z->data[i0] = 0.0;
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            miu3z->data[i0] += G_z->data[i0 + G_z->size[0] * n] * theta->miu3[n];
          }
        }
      } else {
        i0 = G_z_dict->size[1];
        n = G_z_dict->size[0];
        i1 = miu3z->size[0];
        miu3z->size[0] = n;
        emxEnsureCapacity((emxArray__common *)miu3z, i1, sizeof(double));
        n = G_z_dict->size[0];
        nx = miu3z->size[0];
        i1 = miu3z->size[0];
        miu3z->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)miu3z, i1, sizeof(double));
        for (i1 = 0; i1 < nx; i1++) {
          miu3z->data[i1] = 0.0;
        }

        i1 = G_z_dict->size[0];
        if (i1 != 0) {
          idx = 0;
          while ((n > 0) && (idx <= 0)) {
            for (ic = 1; ic <= n; ic++) {
              miu3z->data[ic - 1] = 0.0;
            }

            idx = n;
          }

          br = 0;
          idx = 0;
          while ((n > 0) && (idx <= 0)) {
            ar = 0;
            i1 = br + i0;
            for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
              if (theta->miu3[loop_ub] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= n; ic++) {
                  ia++;
                  miu3z->data[ic] += theta->miu3[loop_ub] * G_z->data[ia - 1];
                }
              }

              ar += n;
            }

            br += i0;
            idx = n;
          }
        }
      }

      /*  Calculate Y star */
      if ((B->size[1] == 1) || (miu3z->size[0] == 1)) {
        i0 = C->size[0];
        C->size[0] = B->size[0];
        emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
        loop_ub = B->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          C->data[i0] = 0.0;
          br = B->size[1];
          for (n = 0; n < br; n++) {
            C->data[i0] += B->data[i0 + B->size[0] * n] * miu3z->data[n];
          }
        }
      } else {
        k = B->size[1];
        unnamed_idx_1 = (unsigned int)B->size[0];
        i0 = C->size[0];
        C->size[0] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
        b_m = B->size[0];
        nx = C->size[0];
        i0 = C->size[0];
        C->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
        for (i0 = 0; i0 < nx; i0++) {
          C->data[i0] = 0.0;
        }

        if (B->size[0] != 0) {
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            for (ic = 1; ic <= b_m; ic++) {
              C->data[ic - 1] = 0.0;
            }

            idx = b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (miu3z->data[loop_ub] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= b_m; ic++) {
                  ia++;
                  C->data[ic] += miu3z->data[loop_ub] * B->data[ia - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx = b_m;
          }
        }
      }

      if ((Beta_v_trans->size[1] == 1) || ((int)varargin_1 == 1)) {
        i0 = nois->size[0];
        nois->size[0] = Beta_v_trans->size[0];
        emxEnsureCapacity((emxArray__common *)nois, i0, sizeof(double));
        loop_ub = Beta_v_trans->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          nois->data[i0] = 0.0;
          br = Beta_v_trans->size[1];
          for (n = 0; n < br; n++) {
            nois->data[i0] += Beta_v_trans->data[i0 + Beta_v_trans->size[0] * n]
              * X_mtx[n];
          }
        }
      } else {
        k = Beta_v_trans->size[1];
        unnamed_idx_1 = (unsigned int)Beta_v_trans->size[0];
        i0 = nois->size[0];
        nois->size[0] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)nois, i0, sizeof(double));
        b_m = Beta_v_trans->size[0];
        nx = nois->size[0];
        i0 = nois->size[0];
        nois->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)nois, i0, sizeof(double));
        for (i0 = 0; i0 < nx; i0++) {
          nois->data[i0] = 0.0;
        }

        if (Beta_v_trans->size[0] != 0) {
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            for (ic = 1; ic <= b_m; ic++) {
              nois->data[ic - 1] = 0.0;
            }

            idx = b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (X_mtx[loop_ub] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= b_m; ic++) {
                  ia++;
                  nois->data[ic] += X_mtx[loop_ub] * Beta_v_trans->data[ia - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx = b_m;
          }
        }
      }

      i0 = Sigma23z->size[0] * Sigma23z->size[1];
      Sigma23z->size[0] = A->size[1];
      Sigma23z->size[1] = A->size[0];
      emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
      loop_ub = A->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = A->size[1];
        for (n = 0; n < br; n++) {
          Sigma23z->data[n + Sigma23z->size[0] * i0] = A->data[i0 + A->size[0] *
            n];
        }
      }

      if (Sigma23z->size[1] == 1) {
        i0 = miu_temp->size[0];
        miu_temp->size[0] = Sigma23z->size[0];
        emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
        loop_ub = Sigma23z->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          miu_temp->data[i0] = 0.0;
          br = Sigma23z->size[1];
          for (n = 0; n < br; n++) {
            miu_temp->data[i0] += Sigma23z->data[i0 + Sigma23z->size[0] * n] *
              Y[n + 60 * v];
          }
        }
      } else {
        k = Sigma23z->size[1];
        unnamed_idx_1 = (unsigned int)Sigma23z->size[0];
        i0 = miu_temp->size[0];
        miu_temp->size[0] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
        b_m = Sigma23z->size[0];
        nx = miu_temp->size[0];
        i0 = miu_temp->size[0];
        miu_temp->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
        for (i0 = 0; i0 < nx; i0++) {
          miu_temp->data[i0] = 0.0;
        }

        if (Sigma23z->size[0] != 0) {
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            for (ic = 1; ic <= b_m; ic++) {
              miu_temp->data[ic - 1] = 0.0;
            }

            idx = b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (Y[loop_ub + 60 * v] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= b_m; ic++) {
                  ia++;
                  miu_temp->data[ic] += Y[loop_ub + 60 * v] * Sigma23z->data[ia
                    - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx = b_m;
          }
        }
      }

      /*  Calculate weighted probability */
      i0 = G_z_dict->size[1];
      if (i0 == 1) {
        i0 = nanid->size[0];
        nanid->size[0] = G_z->size[0];
        emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
        loop_ub = G_z->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          nanid->data[i0] = 0.0;
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            nanid->data[i0] += G_z->data[i0 + G_z->size[0] * n] *
              theta->sigma3_sq[n];
          }
        }
      } else {
        i0 = G_z_dict->size[1];
        n = G_z_dict->size[0];
        i1 = nanid->size[0];
        nanid->size[0] = n;
        emxEnsureCapacity((emxArray__common *)nanid, i1, sizeof(double));
        n = G_z_dict->size[0];
        nx = nanid->size[0];
        i1 = nanid->size[0];
        nanid->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)nanid, i1, sizeof(double));
        for (i1 = 0; i1 < nx; i1++) {
          nanid->data[i1] = 0.0;
        }

        i1 = G_z_dict->size[0];
        if (i1 != 0) {
          idx = 0;
          while ((n > 0) && (idx <= 0)) {
            for (ic = 1; ic <= n; ic++) {
              nanid->data[ic - 1] = 0.0;
            }

            idx = n;
          }

          br = 0;
          idx = 0;
          while ((n > 0) && (idx <= 0)) {
            ar = 0;
            i1 = br + i0;
            for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
              if (theta->sigma3_sq[loop_ub] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= n; ic++) {
                  ia++;
                  nanid->data[ic] += theta->sigma3_sq[loop_ub] * G_z->data[ia -
                    1];
                }
              }

              ar += n;
            }

            br += i0;
            idx = n;
          }
        }
      }

      d_diag(nanid, z_dict);
      blkdiag(Sigma2, z_dict, Sigma23z);
      i0 = G_z_dict->size[1];
      if (i0 == 1) {
        i0 = nanid->size[0];
        nanid->size[0] = G_z->size[0];
        emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
        loop_ub = G_z->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          nanid->data[i0] = 0.0;
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            nanid->data[i0] += G_z->data[i0 + G_z->size[0] * n] * theta->pi[n];
          }
        }
      } else {
        i0 = G_z_dict->size[1];
        n = G_z_dict->size[0];
        i1 = nanid->size[0];
        nanid->size[0] = n;
        emxEnsureCapacity((emxArray__common *)nanid, i1, sizeof(double));
        n = G_z_dict->size[0];
        nx = nanid->size[0];
        i1 = nanid->size[0];
        nanid->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)nanid, i1, sizeof(double));
        for (i1 = 0; i1 < nx; i1++) {
          nanid->data[i1] = 0.0;
        }

        i1 = G_z_dict->size[0];
        if (i1 != 0) {
          idx = 0;
          while ((n > 0) && (idx <= 0)) {
            for (ic = 1; ic <= n; ic++) {
              nanid->data[ic - 1] = 0.0;
            }

            idx = n;
          }

          br = 0;
          idx = 0;
          while ((n > 0) && (idx <= 0)) {
            ar = 0;
            i1 = br + i0;
            for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
              if (theta->pi[loop_ub] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= n; ic++) {
                  ia++;
                  nanid->data[ic] += theta->pi[loop_ub] * G_z->data[ia - 1];
                }
              }

              ar += n;
            }

            br += i0;
            idx = n;
          }
        }
      }

      if ((W2->size[1] == 1) || (Sigma23z->size[0] == 1)) {
        i0 = c_y->size[0] * c_y->size[1];
        c_y->size[0] = W2->size[0];
        c_y->size[1] = Sigma23z->size[1];
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        loop_ub = W2->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = Sigma23z->size[1];
          for (n = 0; n < br; n++) {
            c_y->data[i0 + c_y->size[0] * n] = 0.0;
            nx = W2->size[1];
            for (i1 = 0; i1 < nx; i1++) {
              c_y->data[i0 + c_y->size[0] * n] += W2->data[i0 + W2->size[0] * i1]
                * Sigma23z->data[i1 + Sigma23z->size[0] * n];
            }
          }
        }
      } else {
        k = W2->size[1];
        unnamed_idx_0 = (unsigned int)W2->size[0];
        unnamed_idx_1 = (unsigned int)Sigma23z->size[1];
        i0 = c_y->size[0] * c_y->size[1];
        c_y->size[0] = (int)unnamed_idx_0;
        c_y->size[1] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        b_m = W2->size[0];
        i0 = c_y->size[0] * c_y->size[1];
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        loop_ub = c_y->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = c_y->size[0];
          for (n = 0; n < br; n++) {
            c_y->data[n + c_y->size[0] * i0] = 0.0;
          }
        }

        if ((W2->size[0] == 0) || (Sigma23z->size[1] == 0)) {
        } else {
          nx = W2->size[0] * (Sigma23z->size[1] - 1);
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            i0 = idx + b_m;
            for (ic = idx; ic + 1 <= i0; ic++) {
              c_y->data[ic] = 0.0;
            }

            idx += b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (Sigma23z->data[loop_ub] != 0.0) {
                ia = ar;
                n = idx + b_m;
                for (ic = idx; ic + 1 <= n; ic++) {
                  ia++;
                  c_y->data[ic] += Sigma23z->data[loop_ub] * W2->data[ia - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx += b_m;
          }
        }
      }

      i0 = G_z->size[0] * G_z->size[1];
      G_z->size[0] = W2->size[1];
      G_z->size[1] = W2->size[0];
      emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
      loop_ub = W2->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = W2->size[1];
        for (n = 0; n < br; n++) {
          G_z->data[n + G_z->size[0] * i0] = W2->data[i0 + W2->size[0] * n];
        }
      }

      if ((c_y->size[1] == 1) || (G_z->size[0] == 1)) {
        i0 = z_dict->size[0] * z_dict->size[1];
        z_dict->size[0] = c_y->size[0];
        z_dict->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
        loop_ub = c_y->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            z_dict->data[i0 + z_dict->size[0] * n] = 0.0;
            nx = c_y->size[1];
            for (i1 = 0; i1 < nx; i1++) {
              z_dict->data[i0 + z_dict->size[0] * n] += c_y->data[i0 + c_y->
                size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
            }
          }
        }
      } else {
        k = c_y->size[1];
        unnamed_idx_0 = (unsigned int)c_y->size[0];
        unnamed_idx_1 = (unsigned int)G_z->size[1];
        i0 = z_dict->size[0] * z_dict->size[1];
        z_dict->size[0] = (int)unnamed_idx_0;
        z_dict->size[1] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
        b_m = c_y->size[0];
        i0 = z_dict->size[0] * z_dict->size[1];
        emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
        loop_ub = z_dict->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = z_dict->size[0];
          for (n = 0; n < br; n++) {
            z_dict->data[n + z_dict->size[0] * i0] = 0.0;
          }
        }

        if ((c_y->size[0] == 0) || (G_z->size[1] == 0)) {
        } else {
          nx = c_y->size[0] * (G_z->size[1] - 1);
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            i0 = idx + b_m;
            for (ic = idx; ic + 1 <= i0; ic++) {
              z_dict->data[ic] = 0.0;
            }

            idx += b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (G_z->data[loop_ub] != 0.0) {
                ia = ar;
                n = idx + b_m;
                for (ic = idx; ic + 1 <= n; ic++) {
                  ia++;
                  z_dict->data[ic] += G_z->data[loop_ub] * c_y->data[ia - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx += b_m;
          }
        }
      }

      /* %%% Approximate the above probability by factorization */
      b_log(nanid);
      for (i0 = 0; i0 < 3600; i0++) {
        c_z_dict[i0] = (float)z_dict->data[i0] + Sigma1[i0];
      }

      b_diag(c_z_dict, b_C_matrix_diag);
      b_sqrt(b_C_matrix_diag);
      i0 = b_miu_temp->size[0];
      b_miu_temp->size[0] = miu_temp->size[0];
      emxEnsureCapacity((emxArray__common *)b_miu_temp, i0, sizeof(double));
      loop_ub = miu_temp->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        b_miu_temp->data[i0] = miu_temp->data[i0] - (C->data[i0] + nois->data[i0]);
      }

      normpdf(b_miu_temp, b_C_matrix_diag, fv0);
      for (i0 = 0; i0 < 60; i0++) {
        fv0[i0] += 1.0E-20F;
      }

      c_log(fv0);
      Probzv->data[i] = (float)sum(nanid) + b_sum(fv0);

      /* display('MOVE THIS OUT OF LOOP!!!') */
      /*              Sigma_gamma  = eye((N+1)*q)/(Sigma_gamma0 + diag(1./diag(Sigma23z))); */
      /*              miu_gamma    = Sigma_gamma*W2'*Sigma1_inv*Y_star; */
      /*              miu_star     = P * miu_gamma + [miu_temp; miu3z ]; */
      /*              Sigma_star   = P * Sigma_gamma * P'; */
      /*              miu_sv_all_condz (:, :, i)     = miu_star;                          %store first order moments from this iteration */
      /*              miu_sv_svT_all_condz (:, :, i) = miu_star*miu_star'+Sigma_star;     %store second order moments from this interation */
    }

    /*  end of loop of Z configurations */
    br = 1;
    n = Probzv->size[0];
    y = Probzv->data[0];
    idx = 1;
    if (Probzv->size[0] > 1) {
      if (rtIsNaN(Probzv->data[0])) {
        nx = 2;
        exitg1 = false;
        while ((!exitg1) && (nx <= n)) {
          br = nx;
          if (!rtIsNaN(Probzv->data[nx - 1])) {
            y = Probzv->data[nx - 1];
            idx = nx;
            exitg1 = true;
          } else {
            nx++;
          }
        }
      }

      if (br < Probzv->size[0]) {
        while (br + 1 <= n) {
          if (Probzv->data[br] > y) {
            y = Probzv->data[br];
            idx = br + 1;
          }

          br++;
        }
      }
    }

    VoxelIC->data[v] = idx;
    z_mode->data[v] = idx;

    /* %% Calculate miu_sv_all_condz, miu_sv_svT_all_condz for the maxid */
    loop_ub = G_z_dict->size[0];
    br = G_z_dict->size[1];
    i0 = G_z->size[0] * G_z->size[1];
    G_z->size[0] = loop_ub;
    G_z->size[1] = br;
    emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
    for (i0 = 0; i0 < br; i0++) {
      for (n = 0; n < loop_ub; n++) {
        G_z->data[n + G_z->size[0] * i0] = G_z_dict->data[(n + G_z_dict->size[0]
          * i0) + G_z_dict->size[0] * G_z_dict->size[1] * (idx - 1)];
      }
    }

    i0 = G_z_dict->size[1];
    if (i0 == 1) {
      i0 = miu3z->size[0];
      miu3z->size[0] = G_z->size[0];
      emxEnsureCapacity((emxArray__common *)miu3z, i0, sizeof(double));
      loop_ub = G_z->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        miu3z->data[i0] = 0.0;
        br = G_z->size[1];
        for (n = 0; n < br; n++) {
          miu3z->data[i0] += G_z->data[i0 + G_z->size[0] * n] * theta->miu3[n];
        }
      }
    } else {
      i0 = G_z_dict->size[1];
      n = G_z_dict->size[0];
      i1 = miu3z->size[0];
      miu3z->size[0] = n;
      emxEnsureCapacity((emxArray__common *)miu3z, i1, sizeof(double));
      n = G_z_dict->size[0];
      nx = miu3z->size[0];
      i1 = miu3z->size[0];
      miu3z->size[0] = nx;
      emxEnsureCapacity((emxArray__common *)miu3z, i1, sizeof(double));
      for (i1 = 0; i1 < nx; i1++) {
        miu3z->data[i1] = 0.0;
      }

      i1 = G_z_dict->size[0];
      if (i1 != 0) {
        idx = 0;
        while ((n > 0) && (idx <= 0)) {
          for (ic = 1; ic <= n; ic++) {
            miu3z->data[ic - 1] = 0.0;
          }

          idx = n;
        }

        br = 0;
        idx = 0;
        while ((n > 0) && (idx <= 0)) {
          ar = 0;
          i1 = br + i0;
          for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
            if (theta->miu3[loop_ub] != 0.0) {
              ia = ar;
              for (ic = 0; ic + 1 <= n; ic++) {
                ia++;
                miu3z->data[ic] += theta->miu3[loop_ub] * G_z->data[ia - 1];
              }
            }

            ar += n;
          }

          br += i0;
          idx = n;
        }
      }
    }

    if ((B->size[1] == 1) || (miu3z->size[0] == 1)) {
      i0 = miu_temp->size[0];
      miu_temp->size[0] = B->size[0];
      emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
      loop_ub = B->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        miu_temp->data[i0] = 0.0;
        br = B->size[1];
        for (n = 0; n < br; n++) {
          miu_temp->data[i0] += B->data[i0 + B->size[0] * n] * miu3z->data[n];
        }
      }
    } else {
      k = B->size[1];
      unnamed_idx_1 = (unsigned int)B->size[0];
      i0 = miu_temp->size[0];
      miu_temp->size[0] = (int)unnamed_idx_1;
      emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
      b_m = B->size[0];
      nx = miu_temp->size[0];
      i0 = miu_temp->size[0];
      miu_temp->size[0] = nx;
      emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
      for (i0 = 0; i0 < nx; i0++) {
        miu_temp->data[i0] = 0.0;
      }

      if (B->size[0] != 0) {
        idx = 0;
        while ((b_m > 0) && (idx <= 0)) {
          for (ic = 1; ic <= b_m; ic++) {
            miu_temp->data[ic - 1] = 0.0;
          }

          idx = b_m;
        }

        br = 0;
        idx = 0;
        while ((b_m > 0) && (idx <= 0)) {
          ar = 0;
          i0 = br + k;
          for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
            if (miu3z->data[loop_ub] != 0.0) {
              ia = ar;
              for (ic = 0; ic + 1 <= b_m; ic++) {
                ia++;
                miu_temp->data[ic] += miu3z->data[loop_ub] * B->data[ia - 1];
              }
            }

            ar += b_m;
          }

          br += k;
          idx = b_m;
        }
      }
    }

    if ((Beta_v_trans->size[1] == 1) || ((int)varargin_1 == 1)) {
      i0 = C->size[0];
      C->size[0] = Beta_v_trans->size[0];
      emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
      loop_ub = Beta_v_trans->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        C->data[i0] = 0.0;
        br = Beta_v_trans->size[1];
        for (n = 0; n < br; n++) {
          C->data[i0] += Beta_v_trans->data[i0 + Beta_v_trans->size[0] * n] *
            X_mtx[n];
        }
      }
    } else {
      k = Beta_v_trans->size[1];
      unnamed_idx_1 = (unsigned int)Beta_v_trans->size[0];
      i0 = C->size[0];
      C->size[0] = (int)unnamed_idx_1;
      emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
      b_m = Beta_v_trans->size[0];
      nx = C->size[0];
      i0 = C->size[0];
      C->size[0] = nx;
      emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
      for (i0 = 0; i0 < nx; i0++) {
        C->data[i0] = 0.0;
      }

      if (Beta_v_trans->size[0] != 0) {
        idx = 0;
        while ((b_m > 0) && (idx <= 0)) {
          for (ic = 1; ic <= b_m; ic++) {
            C->data[ic - 1] = 0.0;
          }

          idx = b_m;
        }

        br = 0;
        idx = 0;
        while ((b_m > 0) && (idx <= 0)) {
          ar = 0;
          i0 = br + k;
          for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
            if (X_mtx[loop_ub] != 0.0) {
              ia = ar;
              for (ic = 0; ic + 1 <= b_m; ic++) {
                ia++;
                C->data[ic] += X_mtx[loop_ub] * Beta_v_trans->data[ia - 1];
              }
            }

            ar += b_m;
          }

          br += k;
          idx = b_m;
        }
      }
    }

    i0 = miu_temp->size[0];
    emxEnsureCapacity((emxArray__common *)miu_temp, i0, sizeof(double));
    loop_ub = miu_temp->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      miu_temp->data[i0] += C->data[i0];
    }

    i0 = Sigma23z->size[0] * Sigma23z->size[1];
    Sigma23z->size[0] = A->size[1];
    Sigma23z->size[1] = A->size[0];
    emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
    loop_ub = A->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = A->size[1];
      for (n = 0; n < br; n++) {
        Sigma23z->data[n + Sigma23z->size[0] * i0] = A->data[i0 + A->size[0] * n];
      }
    }

    if (Sigma23z->size[1] == 1) {
      i0 = C->size[0];
      C->size[0] = Sigma23z->size[0];
      emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
      loop_ub = Sigma23z->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        C->data[i0] = 0.0;
        br = Sigma23z->size[1];
        for (n = 0; n < br; n++) {
          C->data[i0] += Sigma23z->data[i0 + Sigma23z->size[0] * n] * Y[n + 60 *
            v];
        }
      }
    } else {
      k = Sigma23z->size[1];
      unnamed_idx_1 = (unsigned int)Sigma23z->size[0];
      i0 = C->size[0];
      C->size[0] = (int)unnamed_idx_1;
      emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
      b_m = Sigma23z->size[0];
      nx = C->size[0];
      i0 = C->size[0];
      C->size[0] = nx;
      emxEnsureCapacity((emxArray__common *)C, i0, sizeof(double));
      for (i0 = 0; i0 < nx; i0++) {
        C->data[i0] = 0.0;
      }

      if (Sigma23z->size[0] != 0) {
        idx = 0;
        while ((b_m > 0) && (idx <= 0)) {
          for (ic = 1; ic <= b_m; ic++) {
            C->data[ic - 1] = 0.0;
          }

          idx = b_m;
        }

        br = 0;
        idx = 0;
        while ((b_m > 0) && (idx <= 0)) {
          ar = 0;
          i0 = br + k;
          for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
            if (Y[loop_ub + 60 * v] != 0.0) {
              ia = ar;
              for (ic = 0; ic + 1 <= b_m; ic++) {
                ia++;
                C->data[ic] += Y[loop_ub + 60 * v] * Sigma23z->data[ia - 1];
              }
            }

            ar += b_m;
          }

          br += k;
          idx = b_m;
        }
      }
    }

    /*  Calculate weighted probability */
    i0 = G_z_dict->size[1];
    if (i0 == 1) {
      i0 = nanid->size[0];
      nanid->size[0] = G_z->size[0];
      emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
      loop_ub = G_z->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        nanid->data[i0] = 0.0;
        br = G_z->size[1];
        for (n = 0; n < br; n++) {
          nanid->data[i0] += G_z->data[i0 + G_z->size[0] * n] * theta->
            sigma3_sq[n];
        }
      }
    } else {
      i0 = G_z_dict->size[1];
      n = G_z_dict->size[0];
      i1 = nanid->size[0];
      nanid->size[0] = n;
      emxEnsureCapacity((emxArray__common *)nanid, i1, sizeof(double));
      n = G_z_dict->size[0];
      nx = nanid->size[0];
      i1 = nanid->size[0];
      nanid->size[0] = nx;
      emxEnsureCapacity((emxArray__common *)nanid, i1, sizeof(double));
      for (i1 = 0; i1 < nx; i1++) {
        nanid->data[i1] = 0.0;
      }

      i1 = G_z_dict->size[0];
      if (i1 != 0) {
        idx = 0;
        while ((n > 0) && (idx <= 0)) {
          for (ic = 1; ic <= n; ic++) {
            nanid->data[ic - 1] = 0.0;
          }

          idx = n;
        }

        br = 0;
        idx = 0;
        while ((n > 0) && (idx <= 0)) {
          ar = 0;
          i1 = br + i0;
          for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
            if (theta->sigma3_sq[loop_ub] != 0.0) {
              ia = ar;
              for (ic = 0; ic + 1 <= n; ic++) {
                ia++;
                nanid->data[ic] += theta->sigma3_sq[loop_ub] * G_z->data[ia - 1];
              }
            }

            ar += n;
          }

          br += i0;
          idx = n;
        }
      }
    }

    d_diag(nanid, z_dict);
    blkdiag(Sigma2, z_dict, Sigma23z);

    /* display('MOVE THIS OUT OF LOOP!!!') */
    e_diag(Sigma23z, nanid);
    rdivide(nanid, nois);
    d_diag(nois, G_z);
    eye((N + 1.0) * q, z_dict);
    i0 = b_Sigma_gamma0->size[0] * b_Sigma_gamma0->size[1];
    b_Sigma_gamma0->size[0] = Sigma_gamma0->size[0];
    b_Sigma_gamma0->size[1] = Sigma_gamma0->size[1];
    emxEnsureCapacity((emxArray__common *)b_Sigma_gamma0, i0, sizeof(float));
    loop_ub = Sigma_gamma0->size[0] * Sigma_gamma0->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b_Sigma_gamma0->data[i0] = Sigma_gamma0->data[i0] + (float)G_z->data[i0];
    }

    b_mrdivide(z_dict, b_Sigma_gamma0, Sigma_gamma);
    i0 = miu_sv_svT->size[0] * miu_sv_svT->size[1];
    miu_sv_svT->size[0] = Sigma_gamma->size[0];
    miu_sv_svT->size[1] = W2->size[0];
    emxEnsureCapacity((emxArray__common *)miu_sv_svT, i0, sizeof(float));
    loop_ub = Sigma_gamma->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = W2->size[0];
      for (n = 0; n < br; n++) {
        miu_sv_svT->data[i0 + miu_sv_svT->size[0] * n] = 0.0F;
        nx = Sigma_gamma->size[1];
        for (i1 = 0; i1 < nx; i1++) {
          miu_sv_svT->data[i0 + miu_sv_svT->size[0] * n] += Sigma_gamma->data[i0
            + Sigma_gamma->size[0] * i1] * (float)W2->data[n + W2->size[0] * i1];
        }
      }
    }

    if (miu_sv_svT->size[1] == 1) {
      i0 = d_y->size[0] * d_y->size[1];
      d_y->size[0] = miu_sv_svT->size[0];
      d_y->size[1] = 60;
      emxEnsureCapacity((emxArray__common *)d_y, i0, sizeof(float));
      loop_ub = miu_sv_svT->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        for (n = 0; n < 60; n++) {
          d_y->data[i0 + d_y->size[0] * n] = 0.0F;
          br = miu_sv_svT->size[1];
          for (i1 = 0; i1 < br; i1++) {
            d_y->data[i0 + d_y->size[0] * n] += miu_sv_svT->data[i0 +
              miu_sv_svT->size[0] * i1] * Sigma1_inv[i1 + 60 * n];
          }
        }
      }
    } else {
      k = miu_sv_svT->size[1];
      unnamed_idx_1 = (unsigned int)miu_sv_svT->size[0];
      i0 = d_y->size[0] * d_y->size[1];
      d_y->size[0] = (int)unnamed_idx_1;
      d_y->size[1] = 60;
      emxEnsureCapacity((emxArray__common *)d_y, i0, sizeof(float));
      b_m = miu_sv_svT->size[0];
      i0 = d_y->size[0] * d_y->size[1];
      d_y->size[1] = 60;
      emxEnsureCapacity((emxArray__common *)d_y, i0, sizeof(float));
      for (i0 = 0; i0 < 60; i0++) {
        loop_ub = d_y->size[0];
        for (n = 0; n < loop_ub; n++) {
          d_y->data[n + d_y->size[0] * i0] = 0.0F;
        }
      }

      if (miu_sv_svT->size[0] != 0) {
        nx = miu_sv_svT->size[0] * 59;
        idx = 0;
        while ((b_m > 0) && (idx <= nx)) {
          i0 = idx + b_m;
          for (ic = idx; ic + 1 <= i0; ic++) {
            d_y->data[ic] = 0.0F;
          }

          idx += b_m;
        }

        br = 0;
        idx = 0;
        while ((b_m > 0) && (idx <= nx)) {
          ar = 0;
          i0 = br + k;
          for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
            if (Sigma1_inv[loop_ub] != 0.0F) {
              ia = ar;
              n = idx + b_m;
              for (ic = idx; ic + 1 <= n; ic++) {
                ia++;
                d_y->data[ic] += Sigma1_inv[loop_ub] * miu_sv_svT->data[ia - 1];
              }
            }

            ar += b_m;
          }

          br += k;
          idx += b_m;
        }
      }
    }

    i0 = b_C->size[0];
    b_C->size[0] = C->size[0];
    emxEnsureCapacity((emxArray__common *)b_C, i0, sizeof(double));
    loop_ub = C->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b_C->data[i0] = C->data[i0] - miu_temp->data[i0];
    }

    i0 = f_y->size[0];
    f_y->size[0] = d_y->size[0];
    emxEnsureCapacity((emxArray__common *)f_y, i0, sizeof(float));
    loop_ub = d_y->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      f_y->data[i0] = 0.0F;
      for (n = 0; n < 60; n++) {
        f_y->data[i0] += d_y->data[i0 + d_y->size[0] * n] * (float)b_C->data[n];
      }
    }

    i0 = b_P->size[0];
    b_P->size[0] = P->size[0];
    emxEnsureCapacity((emxArray__common *)b_P, i0, sizeof(float));
    loop_ub = P->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b_P->data[i0] = 0.0F;
      br = P->size[1];
      for (n = 0; n < br; n++) {
        b_P->data[i0] += (float)P->data[i0 + P->size[0] * n] * f_y->data[n];
      }
    }

    i0 = c_miu_temp->size[0];
    c_miu_temp->size[0] = miu_temp->size[0] + miu3z->size[0];
    emxEnsureCapacity((emxArray__common *)c_miu_temp, i0, sizeof(float));
    loop_ub = miu_temp->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      c_miu_temp->data[i0] = (float)miu_temp->data[i0];
    }

    loop_ub = miu3z->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      c_miu_temp->data[i0 + miu_temp->size[0]] = (float)miu3z->data[i0];
    }

    i0 = miu_star->size[0];
    miu_star->size[0] = b_P->size[0];
    emxEnsureCapacity((emxArray__common *)miu_star, i0, sizeof(float));
    loop_ub = b_P->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      miu_star->data[i0] = b_P->data[i0] + c_miu_temp->data[i0];
    }

    i0 = c_P->size[0] * c_P->size[1];
    c_P->size[0] = P->size[0];
    c_P->size[1] = Sigma_gamma->size[1];
    emxEnsureCapacity((emxArray__common *)c_P, i0, sizeof(float));
    loop_ub = P->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = Sigma_gamma->size[1];
      for (n = 0; n < br; n++) {
        c_P->data[i0 + c_P->size[0] * n] = 0.0F;
        nx = P->size[1];
        for (i1 = 0; i1 < nx; i1++) {
          c_P->data[i0 + c_P->size[0] * n] += (float)P->data[i0 + P->size[0] *
            i1] * Sigma_gamma->data[i1 + Sigma_gamma->size[0] * n];
        }
      }
    }

    i0 = b_miu_star->size[0] * b_miu_star->size[1];
    b_miu_star->size[0] = miu_star->size[0];
    b_miu_star->size[1] = miu_star->size[0];
    emxEnsureCapacity((emxArray__common *)b_miu_star, i0, sizeof(float));
    loop_ub = miu_star->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = miu_star->size[0];
      for (n = 0; n < br; n++) {
        b_miu_star->data[i0 + b_miu_star->size[0] * n] = miu_star->data[i0] *
          miu_star->data[n];
      }
    }

    i0 = d_P->size[0] * d_P->size[1];
    d_P->size[0] = c_P->size[0];
    d_P->size[1] = P->size[0];
    emxEnsureCapacity((emxArray__common *)d_P, i0, sizeof(float));
    loop_ub = c_P->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = P->size[0];
      for (n = 0; n < br; n++) {
        d_P->data[i0 + d_P->size[0] * n] = 0.0F;
        nx = c_P->size[1];
        for (i1 = 0; i1 < nx; i1++) {
          d_P->data[i0 + d_P->size[0] * n] += c_P->data[i0 + c_P->size[0] * i1] *
            (float)P->data[n + P->size[0] * i1];
        }
      }
    }

    i0 = miu_sv_svT_all->size[0] * miu_sv_svT_all->size[1];
    miu_sv_svT_all->size[0] = b_miu_star->size[0];
    miu_sv_svT_all->size[1] = b_miu_star->size[1];
    emxEnsureCapacity((emxArray__common *)miu_sv_svT_all, i0, sizeof(float));
    loop_ub = b_miu_star->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = b_miu_star->size[0];
      for (n = 0; n < br; n++) {
        miu_sv_svT_all->data[n + miu_sv_svT_all->size[0] * i0] =
          b_miu_star->data[n + b_miu_star->size[0] * i0] + d_P->data[n +
          d_P->size[0] * i0];
      }
    }

    /* miu_sv_all     =  miu_sv_all_condz(:,:,maxid); */
    /*  miu_sv_svT_all =  miu_sv_svT_all_condz(:,:,maxid); */
    /*  E(si(v) | Y(v), theta) */
    /* first order moments of si(v) for each subject */
    /* second order moments of si(v) for each subject */
    /* interactions between si(v) and s(v) */
    i0 = miu_svi->size[0] * miu_svi->size[1] * miu_svi->size[2];
    miu_svi->size[0] = (int)q;
    miu_svi->size[1] = 1;
    miu_svi->size[2] = (int)N;
    emxEnsureCapacity((emxArray__common *)miu_svi, i0, sizeof(double));
    i0 = miu_svi_sviT->size[0] * miu_svi_sviT->size[1] * miu_svi_sviT->size[2];
    miu_svi_sviT->size[0] = (int)q;
    miu_svi_sviT->size[1] = (int)q;
    miu_svi_sviT->size[2] = (int)N;
    emxEnsureCapacity((emxArray__common *)miu_svi_sviT, i0, sizeof(double));
    i0 = miu_svi_svT->size[0] * miu_svi_svT->size[1] * miu_svi_svT->size[2];
    miu_svi_svT->size[0] = (int)q;
    miu_svi_svT->size[1] = (int)q;
    miu_svi_svT->size[2] = (int)N;
    emxEnsureCapacity((emxArray__common *)miu_svi_svT, i0, sizeof(double));
    for (i = 0; i < (int)N; i++) {
      /* E(si(v) | Y(v), theta) =  */
      y = ((1.0 + (double)i) - 1.0) * q + 1.0;
      b_y = (1.0 + (double)i) * q;
      if (y > b_y) {
        i0 = 1;
        n = 0;
      } else {
        i0 = (int)y;
        n = (int)b_y;
      }

      loop_ub = n - i0;
      for (n = 0; n <= loop_ub; n++) {
        miu_svi->data[n + miu_svi->size[0] * miu_svi->size[1] * i] =
          miu_star->data[(i0 + n) - 1];
      }

      y = ((1.0 + (double)i) - 1.0) * q + 1.0;
      b_y = (1.0 + (double)i) * q;
      if (y > b_y) {
        i0 = 1;
        n = 0;
      } else {
        i0 = (int)y;
        n = (int)b_y;
      }

      y = ((1.0 + (double)i) - 1.0) * q + 1.0;
      b_y = (1.0 + (double)i) * q;
      if (y > b_y) {
        i1 = 1;
        b_m = 0;
      } else {
        i1 = (int)y;
        b_m = (int)b_y;
      }

      loop_ub = b_m - i1;
      for (b_m = 0; b_m <= loop_ub; b_m++) {
        br = n - i0;
        for (i2 = 0; i2 <= br; i2++) {
          miu_svi_sviT->data[(i2 + miu_svi_sviT->size[0] * b_m) +
            miu_svi_sviT->size[0] * miu_svi_sviT->size[1] * i] =
            miu_sv_svT_all->data[((i0 + i2) + miu_sv_svT_all->size[0] * ((i1 +
            b_m) - 1)) - 1];
        }
      }

      y = ((1.0 + (double)i) - 1.0) * q + 1.0;
      b_y = (1.0 + (double)i) * q;
      if (y > b_y) {
        i0 = 1;
        n = 0;
      } else {
        i0 = (int)y;
        n = (int)b_y;
      }

      y = N * q + 1.0;
      b_y = (N + 1.0) * q;
      if (y > b_y) {
        i1 = 1;
        b_m = 0;
      } else {
        i1 = (int)y;
        b_m = (int)b_y;
      }

      loop_ub = b_m - i1;
      for (b_m = 0; b_m <= loop_ub; b_m++) {
        br = n - i0;
        for (i2 = 0; i2 <= br; i2++) {
          miu_svi_svT->data[(i2 + miu_svi_svT->size[0] * b_m) +
            miu_svi_svT->size[0] * miu_svi_svT->size[1] * i] =
            miu_sv_svT_all->data[((i0 + i2) + miu_sv_svT_all->size[0] * ((i1 +
            b_m) - 1)) - 1];
        }
      }
    }

    y = N * q + 1.0;
    b_y = (N + 1.0) * q;
    if (y > b_y) {
      i0 = 0;
      n = 0;
    } else {
      i0 = (int)y - 1;
      n = (int)b_y;
    }

    i1 = miu_sv->size[0];
    miu_sv->size[0] = n - i0;
    emxEnsureCapacity((emxArray__common *)miu_sv, i1, sizeof(float));
    loop_ub = n - i0;
    for (n = 0; n < loop_ub; n++) {
      miu_sv->data[n] = miu_star->data[i0 + n];
    }

    y = N * q + 1.0;
    b_y = (N + 1.0) * q;
    if (y > b_y) {
      i0 = 0;
      n = 0;
    } else {
      i0 = (int)y - 1;
      n = (int)b_y;
    }

    y = N * q + 1.0;
    b_y = (N + 1.0) * q;
    if (y > b_y) {
      i1 = 0;
      b_m = 0;
    } else {
      i1 = (int)y - 1;
      b_m = (int)b_y;
    }

    i2 = miu_sv_svT->size[0] * miu_sv_svT->size[1];
    miu_sv_svT->size[0] = n - i0;
    miu_sv_svT->size[1] = b_m - i1;
    emxEnsureCapacity((emxArray__common *)miu_sv_svT, i2, sizeof(float));
    loop_ub = b_m - i1;
    for (b_m = 0; b_m < loop_ub; b_m++) {
      br = n - i0;
      for (i2 = 0; i2 < br; i2++) {
        miu_sv_svT->data[i2 + miu_sv_svT->size[0] * b_m] = miu_sv_svT_all->data
          [(i0 + i2) + miu_sv_svT_all->size[0] * (i1 + b_m)];
      }
    }

    /* clear miu_sv_all miu_sv_svT_all; */
    squeeze(miu_svi, r3);
    loop_ub = r3->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = r3->size[0];
      for (n = 0; n < br; n++) {
        subICmean->data[(n + subICmean->size[0] * i0) + subICmean->size[0] *
          subICmean->size[1] * v] = r3->data[n + r3->size[0] * i0];
      }
    }

    /*  E(si(v) | Y(v), theta) */
    loop_ub = miu_svi_sviT->size[2];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = miu_svi_sviT->size[1];
      for (n = 0; n < br; n++) {
        nx = miu_svi_sviT->size[0];
        for (i1 = 0; i1 < nx; i1++) {
          subICvar->data[((i1 + subICvar->size[0] * n) + subICvar->size[0] *
                          subICvar->size[1] * i0) + subICvar->size[0] *
            subICvar->size[1] * subICvar->size[2] * v] = miu_svi_sviT->data[(i1
            + miu_svi_sviT->size[0] * n) + miu_svi_sviT->size[0] *
            miu_svi_sviT->size[1] * i0];
        }
      }
    }

    loop_ub = miu_sv->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      grpICmean->data[i0 + grpICmean->size[0] * v] = miu_sv->data[i0];
    }

    loop_ub = miu_sv_svT->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = miu_sv_svT->size[0];
      for (n = 0; n < br; n++) {
        grpICvar->data[(n + grpICvar->size[0] * i0) + grpICvar->size[0] *
          grpICvar->size[1] * v] = miu_sv_svT->data[n + miu_sv_svT->size[0] * i0];
      }
    }

    /*  E(si(v) | Y(v), theta) */
    permute(miu_svi, miu_svi_trans);
    i0 = mtSum->size[0] * mtSum->size[1] * mtSum->size[2];
    mtSum->size[0] = (int)q;
    mtSum->size[1] = (int)q;
    mtSum->size[2] = (int)N;
    emxEnsureCapacity((emxArray__common *)mtSum, i0, sizeof(double));
    for (nx = 0; nx < (int)N; nx++) {
      memcpy(&c_Y[0], &Y[v * 60], 60U * sizeof(double));
      loop_ub = miu_svi_trans->size[1];
      i0 = b_Y->size[0];
      b_Y->size[0] = (int)q;
      emxEnsureCapacity((emxArray__common *)b_Y, i0, sizeof(double));
      br = (int)q;
      for (i0 = 0; i0 < br; i0++) {
        b_Y->data[i0] = c_Y[i0 + (int)q * nx];
      }

      i0 = b_miu_svi_trans->size[0] * b_miu_svi_trans->size[1];
      b_miu_svi_trans->size[0] = 1;
      b_miu_svi_trans->size[1] = loop_ub;
      emxEnsureCapacity((emxArray__common *)b_miu_svi_trans, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        b_miu_svi_trans->data[b_miu_svi_trans->size[0] * i0] =
          miu_svi_trans->data[miu_svi_trans->size[0] * i0 + miu_svi_trans->size
          [0] * miu_svi_trans->size[1] * nx];
      }

      loop_ub = b_Y->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = b_miu_svi_trans->size[1];
        for (n = 0; n < br; n++) {
          mtSum->data[(i0 + mtSum->size[0] * n) + mtSum->size[0] * mtSum->size[1]
            * nx] = b_Y->data[i0] * b_miu_svi_trans->data[b_miu_svi_trans->size
            [0] * n];
        }
      }
    }

    /*  mtSum =  mtimesx(reshape(Y(:,v),q,1,[]),permute(miu_svi,[2,1,3])); */
    i0 = A_ProdPart1->size[0] * A_ProdPart1->size[1] * A_ProdPart1->size[2];
    emxEnsureCapacity((emxArray__common *)A_ProdPart1, i0, sizeof(double));
    br = A_ProdPart1->size[0];
    nx = A_ProdPart1->size[1];
    idx = A_ProdPart1->size[2];
    loop_ub = br * nx * idx;
    for (i0 = 0; i0 < loop_ub; i0++) {
      A_ProdPart1->data[i0] += mtSum->data[i0];
    }

    i0 = A_ProdPart2->size[0] * A_ProdPart2->size[1] * A_ProdPart2->size[2];
    emxEnsureCapacity((emxArray__common *)A_ProdPart2, i0, sizeof(double));
    br = A_ProdPart2->size[0];
    nx = A_ProdPart2->size[1];
    idx = A_ProdPart2->size[2];
    loop_ub = br * nx * idx;
    for (i0 = 0; i0 < loop_ub; i0++) {
      A_ProdPart2->data[i0] += miu_svi_sviT->data[i0];
    }

    /* beta_new(:,:,v) = beta_new(:,:,v) + mtimesx(X_mtx, permute((bsxfun(@minus, miu_svi, miu_sv)),[2,1,3])); */
    for (i = 0; i < (int)N; i++) {
      loop_ub = beta_new->size[0];
      i0 = ii->size[0];
      ii->size[0] = loop_ub;
      emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
      for (i0 = 0; i0 < loop_ub; i0++) {
        ii->data[i0] = i0;
      }

      loop_ub = beta_new->size[1];
      i0 = r0->size[0];
      r0->size[0] = loop_ub;
      emxEnsureCapacity((emxArray__common *)r0, i0, sizeof(int));
      for (i0 = 0; i0 < loop_ub; i0++) {
        r0->data[i0] = i0;
      }

      loop_ub = miu_svi->size[0];
      i0 = b_miu_svi->size[0] * b_miu_svi->size[1];
      b_miu_svi->size[0] = 1;
      b_miu_svi->size[1] = loop_ub;
      emxEnsureCapacity((emxArray__common *)b_miu_svi, i0, sizeof(float));
      for (i0 = 0; i0 < loop_ub; i0++) {
        b_miu_svi->data[b_miu_svi->size[0] * i0] = (float)miu_svi->data[i0 +
          miu_svi->size[0] * miu_svi->size[1] * i] - miu_sv->data[i0];
      }

      i0 = c_beta_new->size[0] * c_beta_new->size[1];
      c_beta_new->size[0] = 2;
      c_beta_new->size[1] = b_miu_svi->size[1];
      emxEnsureCapacity((emxArray__common *)c_beta_new, i0, sizeof(double));
      for (i0 = 0; i0 < 2; i0++) {
        loop_ub = b_miu_svi->size[1];
        for (n = 0; n < loop_ub; n++) {
          f0 = (float)X_mtx[i0 + (i << 1)] * b_miu_svi->data[b_miu_svi->size[0] *
            n];
          c_beta_new->data[i0 + c_beta_new->size[0] * n] = (float)beta_new->
            data[(i0 + beta_new->size[0] * n) + beta_new->size[0] *
            beta_new->size[1] * v] + f0;
        }
      }

      nx = ii->size[0];
      idx = r0->size[0];
      for (i0 = 0; i0 < idx; i0++) {
        for (n = 0; n < nx; n++) {
          beta_new->data[(ii->data[n] + beta_new->size[0] * r0->data[i0]) +
            beta_new->size[0] * beta_new->size[1] * v] = c_beta_new->data[n + nx
            * i0];
        }
      }
    }

    /* weighting \sum(XiXiT)^{-1}, similar to the design matrix */
    /* ----------------------- Update beta at each voxel ---------------- */
    loop_ub = beta_new->size[0];
    br = beta_new->size[1];
    i0 = G_z->size[0] * G_z->size[1];
    G_z->size[0] = loop_ub;
    G_z->size[1] = br;
    emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
    for (i0 = 0; i0 < br; i0++) {
      for (n = 0; n < loop_ub; n++) {
        G_z->data[n + G_z->size[0] * i0] = beta_new->data[(n + beta_new->size[0]
          * i0) + beta_new->size[0] * beta_new->size[1] * v];
      }
    }

    i0 = beta_new->size[0];
    if (i0 == 1) {
      i0 = z_dict->size[0] * z_dict->size[1];
      z_dict->size[0] = sumXiXiT_inv->size[0];
      z_dict->size[1] = G_z->size[1];
      emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
      loop_ub = sumXiXiT_inv->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = G_z->size[1];
        for (n = 0; n < br; n++) {
          z_dict->data[i0 + z_dict->size[0] * n] = 0.0;
          for (i1 = 0; i1 < 2; i1++) {
            z_dict->data[i0 + z_dict->size[0] * n] += sumXiXiT_inv->data[i0 +
              sumXiXiT_inv->size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
          }
        }
      }
    } else {
      i0 = beta_new->size[1];
      unnamed_idx_0 = (unsigned int)sumXiXiT_inv->size[0];
      n = z_dict->size[0] * z_dict->size[1];
      z_dict->size[0] = (int)unnamed_idx_0;
      z_dict->size[1] = i0;
      emxEnsureCapacity((emxArray__common *)z_dict, n, sizeof(double));
      b_m = sumXiXiT_inv->size[0];
      i0 = z_dict->size[0] * z_dict->size[1];
      emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
      loop_ub = z_dict->size[1];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = z_dict->size[0];
        for (n = 0; n < br; n++) {
          z_dict->data[n + z_dict->size[0] * i0] = 0.0;
        }
      }

      if (sumXiXiT_inv->size[0] == 0) {
      } else {
        i0 = beta_new->size[1];
        if (i0 == 0) {
        } else {
          i0 = beta_new->size[1] - 1;
          nx = sumXiXiT_inv->size[0] * i0;
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            i0 = idx + b_m;
            for (ic = idx; ic + 1 <= i0; ic++) {
              z_dict->data[ic] = 0.0;
            }

            idx += b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            ar = 0;
            for (loop_ub = br; loop_ub + 1 <= br + 2; loop_ub++) {
              if (G_z->data[loop_ub] != 0.0) {
                ia = ar;
                i0 = idx + b_m;
                for (ic = idx; ic + 1 <= i0; ic++) {
                  ia++;
                  z_dict->data[ic] += G_z->data[loop_ub] * sumXiXiT_inv->data[ia
                    - 1];
                }
              }

              ar += b_m;
            }

            br += 2;
            idx += b_m;
          }
        }
      }
    }

    loop_ub = z_dict->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = z_dict->size[0];
      for (n = 0; n < br; n++) {
        beta_new->data[(n + beta_new->size[0] * i0) + beta_new->size[0] *
          beta_new->size[1] * v] = z_dict->data[n + z_dict->size[0] * i0];
      }
    }

    /*  new beta(v), coefficient matrix at voxel v */
    /* %% Update for sigma2 requires beta_new */
    /* sigma2_sq_all_V(:,:,v) = sum(miu_svi_sviT,3) + miu_sv_svT -2*sum(miu_svi_svT,3) ... */
    /*     + 2*sum(mtimesx(bsxfun(@minus,miu_sv,miu_svi),X_mtx'*beta_new(:,:,v)),3) ... */
    /*     + beta_new(:,:,v)'* X_mtx * X_mtx'*beta_new(:,:,v); */
    for (i = 0; i < (int)N; i++) {
      /*   XXX + ...... 2(XXX - E(si(v) | Y(v), theta)) * ... */
      loop_ub = beta_new->size[0];
      br = beta_new->size[1];
      i0 = Sigma23z->size[0] * Sigma23z->size[1];
      Sigma23z->size[0] = br;
      Sigma23z->size[1] = loop_ub;
      emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        for (n = 0; n < br; n++) {
          Sigma23z->data[n + Sigma23z->size[0] * i0] = beta_new->data[(i0 +
            beta_new->size[0] * n) + beta_new->size[0] * beta_new->size[1] * v];
        }
      }

      if (Sigma23z->size[1] == 1) {
        i0 = nanid->size[0];
        nanid->size[0] = Sigma23z->size[0];
        emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
        loop_ub = Sigma23z->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          nanid->data[i0] = 0.0;
          br = Sigma23z->size[1];
          for (n = 0; n < br; n++) {
            nanid->data[i0] += Sigma23z->data[i0 + Sigma23z->size[0] * n] *
              X_mtx[n + (i << 1)];
          }
        }
      } else {
        k = Sigma23z->size[1];
        unnamed_idx_1 = (unsigned int)Sigma23z->size[0];
        i0 = nanid->size[0];
        nanid->size[0] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
        b_m = Sigma23z->size[0];
        nx = nanid->size[0];
        i0 = nanid->size[0];
        nanid->size[0] = nx;
        emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
        for (i0 = 0; i0 < nx; i0++) {
          nanid->data[i0] = 0.0;
        }

        if (Sigma23z->size[0] != 0) {
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            for (ic = 1; ic <= b_m; ic++) {
              nanid->data[ic - 1] = 0.0;
            }

            idx = b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= 0)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (X_mtx[loop_ub + (i << 1)] != 0.0) {
                ia = ar;
                for (ic = 0; ic + 1 <= b_m; ic++) {
                  ia++;
                  nanid->data[ic] += X_mtx[loop_ub + (i << 1)] * Sigma23z->
                    data[ia - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx = b_m;
          }
        }
      }

      i0 = e_y->size[0] * e_y->size[1];
      e_y->size[0] = nanid->size[0];
      e_y->size[1] = 2;
      emxEnsureCapacity((emxArray__common *)e_y, i0, sizeof(double));
      loop_ub = nanid->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        for (n = 0; n < 2; n++) {
          e_y->data[i0 + e_y->size[0] * n] = nanid->data[i0] * X_mtx[n + (i << 1)];
        }
      }

      loop_ub = beta_new->size[0];
      br = beta_new->size[1];
      i0 = G_z->size[0] * G_z->size[1];
      G_z->size[0] = loop_ub;
      G_z->size[1] = br;
      emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
      for (i0 = 0; i0 < br; i0++) {
        for (n = 0; n < loop_ub; n++) {
          G_z->data[n + G_z->size[0] * i0] = beta_new->data[(n + beta_new->size
            [0] * i0) + beta_new->size[0] * beta_new->size[1] * v];
        }
      }

      i0 = beta_new->size[0];
      if (i0 == 1) {
        i0 = z_dict->size[0] * z_dict->size[1];
        z_dict->size[0] = e_y->size[0];
        z_dict->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
        loop_ub = e_y->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            z_dict->data[i0 + z_dict->size[0] * n] = 0.0;
            for (i1 = 0; i1 < 2; i1++) {
              z_dict->data[i0 + z_dict->size[0] * n] += e_y->data[i0 + e_y->
                size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
            }
          }
        }
      } else {
        i0 = beta_new->size[1];
        unnamed_idx_0 = (unsigned int)e_y->size[0];
        n = z_dict->size[0] * z_dict->size[1];
        z_dict->size[0] = (int)unnamed_idx_0;
        z_dict->size[1] = i0;
        emxEnsureCapacity((emxArray__common *)z_dict, n, sizeof(double));
        b_m = e_y->size[0];
        i0 = z_dict->size[0] * z_dict->size[1];
        emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
        loop_ub = z_dict->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = z_dict->size[0];
          for (n = 0; n < br; n++) {
            z_dict->data[n + z_dict->size[0] * i0] = 0.0;
          }
        }

        if (e_y->size[0] == 0) {
        } else {
          i0 = beta_new->size[1];
          if (i0 == 0) {
          } else {
            i0 = beta_new->size[1] - 1;
            nx = e_y->size[0] * i0;
            idx = 0;
            while ((b_m > 0) && (idx <= nx)) {
              i0 = idx + b_m;
              for (ic = idx; ic + 1 <= i0; ic++) {
                z_dict->data[ic] = 0.0;
              }

              idx += b_m;
            }

            br = 0;
            idx = 0;
            while ((b_m > 0) && (idx <= nx)) {
              ar = 0;
              for (loop_ub = br; loop_ub + 1 <= br + 2; loop_ub++) {
                if (G_z->data[loop_ub] != 0.0) {
                  ia = ar;
                  i0 = idx + b_m;
                  for (ic = idx; ic + 1 <= i0; ic++) {
                    ia++;
                    z_dict->data[ic] += G_z->data[loop_ub] * e_y->data[ia - 1];
                  }
                }

                ar += b_m;
              }

              br += 2;
              idx += b_m;
            }
          }
        }
      }

      i0 = r4->size[0];
      r4->size[0] = miu_sv->size[0];
      emxEnsureCapacity((emxArray__common *)r4, i0, sizeof(float));
      loop_ub = miu_sv->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        r4->data[i0] = 2.0F * (miu_sv->data[i0] - (float)miu_svi->data[i0 +
          miu_svi->size[0] * miu_svi->size[1] * i]);
      }

      loop_ub = beta_new->size[0];
      br = beta_new->size[1];
      i0 = r5->size[0] * r5->size[1];
      r5->size[0] = r4->size[0];
      r5->size[1] = 2;
      emxEnsureCapacity((emxArray__common *)r5, i0, sizeof(float));
      nx = r4->size[0];
      for (i0 = 0; i0 < nx; i0++) {
        for (n = 0; n < 2; n++) {
          r5->data[i0 + r5->size[0] * n] = r4->data[i0] * (float)X_mtx[n + (i <<
            1)];
        }
      }

      i0 = b_beta_new->size[0] * b_beta_new->size[1];
      b_beta_new->size[0] = loop_ub;
      b_beta_new->size[1] = br;
      emxEnsureCapacity((emxArray__common *)b_beta_new, i0, sizeof(float));
      for (i0 = 0; i0 < br; i0++) {
        for (n = 0; n < loop_ub; n++) {
          b_beta_new->data[n + b_beta_new->size[0] * i0] = (float)beta_new->
            data[(n + beta_new->size[0] * i0) + beta_new->size[0] *
            beta_new->size[1] * v];
        }
      }

      i0 = b_sigma2_sq_all_V->size[0] * b_sigma2_sq_all_V->size[1];
      b_sigma2_sq_all_V->size[0] = r5->size[0];
      b_sigma2_sq_all_V->size[1] = b_beta_new->size[1];
      emxEnsureCapacity((emxArray__common *)b_sigma2_sq_all_V, i0, sizeof(double));
      loop_ub = r5->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = b_beta_new->size[1];
        for (n = 0; n < br; n++) {
          f0 = 0.0F;
          for (i1 = 0; i1 < 2; i1++) {
            f0 += r5->data[i0 + r5->size[0] * i1] * b_beta_new->data[i1 +
              b_beta_new->size[0] * n];
          }

          b_sigma2_sq_all_V->data[i0 + b_sigma2_sq_all_V->size[0] * n] =
            ((((float)(sigma2_sq_all_V->data[(i0 + sigma2_sq_all_V->size[0] * n)
                       + sigma2_sq_all_V->size[0] * sigma2_sq_all_V->size[1] * v]
                       + miu_svi_sviT->data[(i0 + miu_svi_sviT->size[0] * n) +
                       miu_svi_sviT->size[0] * miu_svi_sviT->size[1] * i]) +
               miu_sv_svT->data[i0 + miu_sv_svT->size[0] * n]) - (float)(2.0 *
               miu_svi_svT->data[(i0 + miu_svi_svT->size[0] * n) +
               miu_svi_svT->size[0] * miu_svi_svT->size[1] * i])) + f0) + (float)
            z_dict->data[i0 + z_dict->size[0] * n];
        }
      }

      loop_ub = b_sigma2_sq_all_V->size[1];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = b_sigma2_sq_all_V->size[0];
        for (n = 0; n < br; n++) {
          sigma2_sq_all_V->data[(n + sigma2_sq_all_V->size[0] * i0) +
            sigma2_sq_all_V->size[0] * sigma2_sq_all_V->size[1] * v] =
            b_sigma2_sq_all_V->data[n + b_sigma2_sq_all_V->size[0] * i0];
        }
      }
    }

    v++;
  }

  emxFree_real_T(&b_miu_svi_trans);
  emxFree_real_T(&b_Y);
  emxFree_real_T(&c_beta_new);
  emxFree_real32_T(&b_miu_svi);
  emxFree_real_T(&b_sigma2_sq_all_V);
  emxFree_real32_T(&b_beta_new);
  emxFree_real32_T(&r5);
  emxFree_real32_T(&r4);
  emxFree_real32_T(&d_P);
  emxFree_real32_T(&b_miu_star);
  emxFree_real32_T(&c_P);
  emxFree_real32_T(&c_miu_temp);
  emxFree_real32_T(&b_P);
  emxFree_real32_T(&f_y);
  emxFree_real_T(&b_C);
  emxFree_real_T(&b_miu_temp);
  emxFree_real32_T(&b_Sigma_gamma0);
  emxFree_real_T(&r3);
  emxFree_real_T(&e_y);
  emxFree_real32_T(&d_y);
  emxFree_real_T(&C);
  emxFree_int32_T(&r0);
  emxFree_real_T(&miu_svi_trans);
  emxFree_real_T(&mtSum);
  emxFree_real32_T(&miu_sv_svT);
  emxFree_real32_T(&miu_sv);
  emxFree_real_T(&miu_svi_svT);
  emxFree_real_T(&miu_svi_sviT);
  emxFree_real_T(&miu_svi);
  emxFree_real32_T(&miu_sv_svT_all);
  emxFree_real32_T(&miu_star);
  emxFree_real32_T(&Sigma_gamma);
  emxFree_real_T(&miu_temp);
  emxFree_real_T(&miu3z);
  emxFree_real_T(&Probzv);
  emxFree_real_T(&Beta_v_trans);
  emxFree_real32_T(&Sigma_gamma0);
  emxFree_real_T(&Sigma2);
  emxFree_real_T(&P);
  emxFree_real_T(&W2);
  emxFree_real_T(&B);
  emxFree_real_T(&A);
  emxFree_real_T(&sumXiXiT_inv);
  c_sum(sigma2_sq_all_V, z_dict);
  y = 1.0 / (N * V);
  e_diag(z_dict, nanid);
  i0 = theta_new->sigma2_sq->size[0];
  theta_new->sigma2_sq->size[0] = nanid->size[0];
  emxEnsureCapacity((emxArray__common *)theta_new->sigma2_sq, i0, sizeof(double));
  loop_ub = nanid->size[0];
  emxFree_real_T(&sigma2_sq_all_V);
  for (i0 = 0; i0 < loop_ub; i0++) {
    theta_new->sigma2_sq->data[i0] = y * nanid->data[i0];
  }

  /*  new sigma2_sq */
  ar = 0;
  emxInit_boolean_T(&b, 1);
  emxInit_real_T(&b_grpICvar, 3);
  emxInit_real_T(&c_grpICvar, 3);
  emxInit_real_T1(&b_grpICmean, 2);
  emxInit_real_T1(&c_grpICmean, 2);
  while (ar <= (int)q - 1) {
    i0 = b->size[0];
    b->size[0] = VoxelIC->size[0];
    emxEnsureCapacity((emxArray__common *)b, i0, sizeof(boolean_T));
    loop_ub = VoxelIC->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b->data[i0] = (VoxelIC->data[i0] == 1.0 + (double)ar);
    }

    nx = b->size[0];
    idx = 0;
    i0 = ii->size[0];
    ii->size[0] = b->size[0];
    emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
    br = 1;
    exitg1 = false;
    while ((!exitg1) && (br <= nx)) {
      if (b->data[br - 1]) {
        idx++;
        ii->data[idx - 1] = br;
        if (idx >= nx) {
          exitg1 = true;
        } else {
          br++;
        }
      } else {
        br++;
      }
    }

    if (b->size[0] == 1) {
      if (idx == 0) {
        i0 = ii->size[0];
        ii->size[0] = 0;
        emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
      }
    } else {
      i0 = ii->size[0];
      if (1 > idx) {
        ii->size[0] = 0;
      } else {
        ii->size[0] = idx;
      }

      emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
    }

    i0 = nanid->size[0];
    nanid->size[0] = ii->size[0];
    emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
    loop_ub = ii->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      nanid->data[i0] = ii->data[i0];
    }

    i0 = b->size[0];
    b->size[0] = VoxelIC->size[0];
    emxEnsureCapacity((emxArray__common *)b, i0, sizeof(boolean_T));
    loop_ub = VoxelIC->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b->data[i0] = (VoxelIC->data[i0] != 1.0 + (double)ar);
    }

    nx = b->size[0];
    idx = 0;
    i0 = ii->size[0];
    ii->size[0] = b->size[0];
    emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
    br = 1;
    exitg1 = false;
    while ((!exitg1) && (br <= nx)) {
      if (b->data[br - 1]) {
        idx++;
        ii->data[idx - 1] = br;
        if (idx >= nx) {
          exitg1 = true;
        } else {
          br++;
        }
      } else {
        br++;
      }
    }

    if (b->size[0] == 1) {
      if (idx == 0) {
        i0 = ii->size[0];
        ii->size[0] = 0;
        emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
      }
    } else {
      i0 = ii->size[0];
      if (1 > idx) {
        ii->size[0] = 0;
      } else {
        ii->size[0] = idx;
      }

      emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
    }

    i0 = nois->size[0];
    nois->size[0] = ii->size[0];
    emxEnsureCapacity((emxArray__common *)nois, i0, sizeof(double));
    loop_ub = ii->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      nois->data[i0] = ii->data[i0];
    }

    theta_new->pi->data[(int)(1.0 + ((1.0 + (double)ar) - 1.0) * m) - 1] =
      ((double)nanid->size[0] + 1.0) / (((double)nois->size[0] + (double)
      nanid->size[0]) + 1.0);

    /* %%%% in case no activation is identified */
    theta_new->pi->data[(int)(2.0 + ((1.0 + (double)ar) - 1.0) * m) - 1] =
      (double)nois->size[0] / (((double)nois->size[0] + (double)nanid->size[0])
      + 1.0);
    i0 = c_grpICmean->size[0] * c_grpICmean->size[1];
    c_grpICmean->size[0] = 1;
    c_grpICmean->size[1] = nanid->size[0];
    emxEnsureCapacity((emxArray__common *)c_grpICmean, i0, sizeof(double));
    loop_ub = nanid->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      c_grpICmean->data[c_grpICmean->size[0] * i0] = grpICmean->data[ar +
        grpICmean->size[0] * ((int)nanid->data[i0] - 1)];
    }

    theta_new->miu3->data[(int)(1.0 + ((1.0 + (double)ar) - 1.0) * m) - 1] =
      mean(c_grpICmean);
    i0 = b_grpICmean->size[0] * b_grpICmean->size[1];
    b_grpICmean->size[0] = 1;
    b_grpICmean->size[1] = nois->size[0];
    emxEnsureCapacity((emxArray__common *)b_grpICmean, i0, sizeof(double));
    loop_ub = nois->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b_grpICmean->data[b_grpICmean->size[0] * i0] = grpICmean->data[ar +
        grpICmean->size[0] * ((int)nois->data[i0] - 1)];
    }

    theta_new->miu3->data[(int)(2.0 + ((1.0 + (double)ar) - 1.0) * m) - 1] =
      mean(b_grpICmean);
    i0 = c_grpICvar->size[0] * c_grpICvar->size[1] * c_grpICvar->size[2];
    c_grpICvar->size[0] = 1;
    c_grpICvar->size[1] = 1;
    c_grpICvar->size[2] = nanid->size[0];
    emxEnsureCapacity((emxArray__common *)c_grpICvar, i0, sizeof(double));
    loop_ub = nanid->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      c_grpICvar->data[c_grpICvar->size[0] * c_grpICvar->size[1] * i0] =
        grpICvar->data[(ar + grpICvar->size[0] * ar) + grpICvar->size[0] *
        grpICvar->size[1] * ((int)nanid->data[i0] - 1)];
    }

    theta_new->sigma3_sq->data[(int)(1.0 + ((1.0 + (double)ar) - 1.0) * m) - 1] =
      b_mean(c_grpICvar);
    i0 = b_grpICvar->size[0] * b_grpICvar->size[1] * b_grpICvar->size[2];
    b_grpICvar->size[0] = 1;
    b_grpICvar->size[1] = 1;
    b_grpICvar->size[2] = nois->size[0];
    emxEnsureCapacity((emxArray__common *)b_grpICvar, i0, sizeof(double));
    loop_ub = nois->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      b_grpICvar->data[b_grpICvar->size[0] * b_grpICvar->size[1] * i0] =
        grpICvar->data[(ar + grpICvar->size[0] * ar) + grpICvar->size[0] *
        grpICvar->size[1] * ((int)nois->data[i0] - 1)];
    }

    theta_new->sigma3_sq->data[(int)(2.0 + ((1.0 + (double)ar) - 1.0) * m) - 1] =
      b_mean(b_grpICvar);
    ar++;
  }

  emxFree_real_T(&c_grpICmean);
  emxFree_real_T(&b_grpICmean);
  emxFree_real_T(&c_grpICvar);
  emxFree_real_T(&b_grpICvar);
  emxFree_real_T(&nois);
  emxFree_real_T(&VoxelIC);
  power(theta_new->miu3, nanid);
  i0 = theta_new->sigma3_sq->size[0];
  emxEnsureCapacity((emxArray__common *)theta_new->sigma3_sq, i0, sizeof(double));
  loop_ub = theta_new->sigma3_sq->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    theta_new->sigma3_sq->data[i0] -= nanid->data[i0];
  }

  /*  new sigma3 */
  /* %%% Handle NaN in previous iteration */
  i0 = b->size[0];
  b->size[0] = theta_new->miu3->size[0];
  emxEnsureCapacity((emxArray__common *)b, i0, sizeof(boolean_T));
  loop_ub = theta_new->miu3->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    b->data[i0] = rtIsNaN(theta_new->miu3->data[i0]);
  }

  nx = b->size[0];
  idx = 0;
  i0 = ii->size[0];
  ii->size[0] = b->size[0];
  emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
  br = 1;
  exitg1 = false;
  while ((!exitg1) && (br <= nx)) {
    if (b->data[br - 1]) {
      idx++;
      ii->data[idx - 1] = br;
      if (idx >= nx) {
        exitg1 = true;
      } else {
        br++;
      }
    } else {
      br++;
    }
  }

  if (b->size[0] == 1) {
    if (idx == 0) {
      i0 = ii->size[0];
      ii->size[0] = 0;
      emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
    }
  } else {
    i0 = ii->size[0];
    if (1 > idx) {
      ii->size[0] = 0;
    } else {
      ii->size[0] = idx;
    }

    emxEnsureCapacity((emxArray__common *)ii, i0, sizeof(int));
  }

  emxFree_boolean_T(&b);
  i0 = nanid->size[0];
  nanid->size[0] = ii->size[0];
  emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
  loop_ub = ii->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    nanid->data[i0] = ii->data[i0];
  }

  emxFree_int32_T(&ii);
  if (!(nanid->size[0] == 0)) {
    loop_ub = nanid->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      theta_new->sigma3_sq->data[(int)nanid->data[i0] - 1] = theta->sigma3_sq
        [(int)nanid->data[i0] - 1];
    }

    loop_ub = nanid->size[0];
    for (i0 = 0; i0 < loop_ub; i0++) {
      theta_new->miu3->data[(int)nanid->data[i0] - 1] = theta->miu3[(int)
        nanid->data[i0] - 1];
    }
  }

  /*  This is the code from approx non experimental */
  i = 0;
  emxInit_creal_T(&r6, 2);
  emxInit_real_T1(&b_A_ProdPart2, 2);
  while (i <= (int)N - 1) {
    loop_ub = A_ProdPart1->size[0];
    br = A_ProdPart1->size[1];
    i0 = Sigma23z->size[0] * Sigma23z->size[1];
    Sigma23z->size[0] = loop_ub;
    Sigma23z->size[1] = br;
    emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
    for (i0 = 0; i0 < br; i0++) {
      for (n = 0; n < loop_ub; n++) {
        Sigma23z->data[n + Sigma23z->size[0] * i0] = A_ProdPart1->data[(n +
          A_ProdPart1->size[0] * i0) + A_ProdPart1->size[0] * A_ProdPart1->size
          [1] * i];
      }
    }

    loop_ub = A_ProdPart2->size[0];
    br = A_ProdPart2->size[1];
    i0 = b_A_ProdPart2->size[0] * b_A_ProdPart2->size[1];
    b_A_ProdPart2->size[0] = loop_ub;
    b_A_ProdPart2->size[1] = br;
    emxEnsureCapacity((emxArray__common *)b_A_ProdPart2, i0, sizeof(double));
    for (i0 = 0; i0 < br; i0++) {
      for (n = 0; n < loop_ub; n++) {
        b_A_ProdPart2->data[n + b_A_ProdPart2->size[0] * i0] = A_ProdPart2->
          data[(n + A_ProdPart2->size[0] * i0) + A_ProdPart2->size[0] *
          A_ProdPart2->size[1] * i];
      }
    }

    inv(b_A_ProdPart2, G_z);
    i0 = A_ProdPart1->size[1];
    if ((i0 == 1) || (G_z->size[0] == 1)) {
      i0 = z_dict->size[0] * z_dict->size[1];
      z_dict->size[0] = Sigma23z->size[0];
      z_dict->size[1] = G_z->size[1];
      emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
      loop_ub = Sigma23z->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = G_z->size[1];
        for (n = 0; n < br; n++) {
          z_dict->data[i0 + z_dict->size[0] * n] = 0.0;
          nx = Sigma23z->size[1];
          for (i1 = 0; i1 < nx; i1++) {
            z_dict->data[i0 + z_dict->size[0] * n] += Sigma23z->data[i0 +
              Sigma23z->size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
          }
        }
      }
    } else {
      i0 = A_ProdPart1->size[1];
      n = A_ProdPart1->size[0];
      unnamed_idx_1 = (unsigned int)G_z->size[1];
      i1 = z_dict->size[0] * z_dict->size[1];
      z_dict->size[0] = n;
      z_dict->size[1] = (int)unnamed_idx_1;
      emxEnsureCapacity((emxArray__common *)z_dict, i1, sizeof(double));
      n = A_ProdPart1->size[0];
      i1 = z_dict->size[0] * z_dict->size[1];
      emxEnsureCapacity((emxArray__common *)z_dict, i1, sizeof(double));
      loop_ub = z_dict->size[1];
      for (i1 = 0; i1 < loop_ub; i1++) {
        br = z_dict->size[0];
        for (b_m = 0; b_m < br; b_m++) {
          z_dict->data[b_m + z_dict->size[0] * i1] = 0.0;
        }
      }

      i1 = A_ProdPart1->size[0];
      if ((i1 == 0) || (G_z->size[1] == 0)) {
      } else {
        i1 = A_ProdPart1->size[0];
        nx = i1 * (G_z->size[1] - 1);
        idx = 0;
        while ((n > 0) && (idx <= nx)) {
          i1 = idx + n;
          for (ic = idx; ic + 1 <= i1; ic++) {
            z_dict->data[ic] = 0.0;
          }

          idx += n;
        }

        br = 0;
        idx = 0;
        while ((n > 0) && (idx <= nx)) {
          ar = 0;
          i1 = br + i0;
          for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
            if (G_z->data[loop_ub] != 0.0) {
              ia = ar;
              b_m = idx + n;
              for (ic = idx; ic + 1 <= b_m; ic++) {
                ia++;
                z_dict->data[ic] += G_z->data[loop_ub] * Sigma23z->data[ia - 1];
              }
            }

            ar += n;
          }

          br += i0;
          idx += n;
        }
      }
    }

    loop_ub = z_dict->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = z_dict->size[0];
      for (n = 0; n < br; n++) {
        theta_new->A->data[(n + theta_new->A->size[0] * i0) + theta_new->A->
          size[0] * theta_new->A->size[1] * i] = z_dict->data[n + z_dict->size[0]
          * i0];
      }
    }

    /* new Ai */
    /*  Symmetric orthogonalization.  */
    loop_ub = theta_new->A->size[0];
    br = theta_new->A->size[1];
    i0 = Sigma23z->size[0] * Sigma23z->size[1];
    Sigma23z->size[0] = br;
    Sigma23z->size[1] = loop_ub;
    emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
    for (i0 = 0; i0 < loop_ub; i0++) {
      for (n = 0; n < br; n++) {
        Sigma23z->data[n + Sigma23z->size[0] * i0] = theta_new->A->data[(i0 +
          theta_new->A->size[0] * n) + theta_new->A->size[0] * theta_new->
          A->size[1] * i];
      }
    }

    loop_ub = theta_new->A->size[0];
    br = theta_new->A->size[1];
    i0 = G_z->size[0] * G_z->size[1];
    G_z->size[0] = loop_ub;
    G_z->size[1] = br;
    emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
    for (i0 = 0; i0 < br; i0++) {
      for (n = 0; n < loop_ub; n++) {
        G_z->data[n + G_z->size[0] * i0] = theta_new->A->data[(n + theta_new->
          A->size[0] * i0) + theta_new->A->size[0] * theta_new->A->size[1] * i];
      }
    }

    guard1 = false;
    if (Sigma23z->size[1] == 1) {
      guard1 = true;
    } else {
      i0 = theta_new->A->size[0];
      if (i0 == 1) {
        guard1 = true;
      } else {
        k = Sigma23z->size[1];
        i0 = theta_new->A->size[1];
        unnamed_idx_0 = (unsigned int)Sigma23z->size[0];
        n = c_y->size[0] * c_y->size[1];
        c_y->size[0] = (int)unnamed_idx_0;
        c_y->size[1] = i0;
        emxEnsureCapacity((emxArray__common *)c_y, n, sizeof(double));
        b_m = Sigma23z->size[0];
        i0 = c_y->size[0] * c_y->size[1];
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        loop_ub = c_y->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = c_y->size[0];
          for (n = 0; n < br; n++) {
            c_y->data[n + c_y->size[0] * i0] = 0.0;
          }
        }

        if (Sigma23z->size[0] == 0) {
        } else {
          i0 = theta_new->A->size[1];
          if (i0 == 0) {
          } else {
            i0 = theta_new->A->size[1] - 1;
            nx = Sigma23z->size[0] * i0;
            idx = 0;
            while ((b_m > 0) && (idx <= nx)) {
              i0 = idx + b_m;
              for (ic = idx; ic + 1 <= i0; ic++) {
                c_y->data[ic] = 0.0;
              }

              idx += b_m;
            }

            br = 0;
            idx = 0;
            while ((b_m > 0) && (idx <= nx)) {
              ar = 0;
              i0 = br + k;
              for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
                if (G_z->data[loop_ub] != 0.0) {
                  ia = ar;
                  n = idx + b_m;
                  for (ic = idx; ic + 1 <= n; ic++) {
                    ia++;
                    c_y->data[ic] += G_z->data[loop_ub] * Sigma23z->data[ia - 1];
                  }
                }

                ar += b_m;
              }

              br += k;
              idx += b_m;
            }
          }
        }
      }
    }

    if (guard1) {
      i0 = c_y->size[0] * c_y->size[1];
      c_y->size[0] = Sigma23z->size[0];
      c_y->size[1] = G_z->size[1];
      emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
      loop_ub = Sigma23z->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = G_z->size[1];
        for (n = 0; n < br; n++) {
          c_y->data[i0 + c_y->size[0] * n] = 0.0;
          nx = Sigma23z->size[1];
          for (i1 = 0; i1 < nx; i1++) {
            c_y->data[i0 + c_y->size[0] * n] += Sigma23z->data[i0 +
              Sigma23z->size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
          }
        }
      }
    }

    loop_ub = theta_new->A->size[0];
    br = theta_new->A->size[1];
    i0 = Sigma23z->size[0] * Sigma23z->size[1];
    Sigma23z->size[0] = loop_ub;
    Sigma23z->size[1] = br;
    emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
    for (i0 = 0; i0 < br; i0++) {
      for (n = 0; n < loop_ub; n++) {
        Sigma23z->data[n + Sigma23z->size[0] * i0] = theta_new->A->data[(n +
          theta_new->A->size[0] * i0) + theta_new->A->size[0] * theta_new->
          A->size[1] * i];
      }
    }

    inv(c_y, G_z);
    sqrtm(G_z, r6);
    i0 = G_z->size[0] * G_z->size[1];
    G_z->size[0] = r6->size[0];
    G_z->size[1] = r6->size[1];
    emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
    loop_ub = r6->size[0] * r6->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      G_z->data[i0] = r6->data[i0].re;
    }

    i0 = theta_new->A->size[1];
    if ((i0 == 1) || (G_z->size[0] == 1)) {
      i0 = z_dict->size[0] * z_dict->size[1];
      z_dict->size[0] = Sigma23z->size[0];
      z_dict->size[1] = G_z->size[1];
      emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
      loop_ub = Sigma23z->size[0];
      for (i0 = 0; i0 < loop_ub; i0++) {
        br = G_z->size[1];
        for (n = 0; n < br; n++) {
          z_dict->data[i0 + z_dict->size[0] * n] = 0.0;
          nx = Sigma23z->size[1];
          for (i1 = 0; i1 < nx; i1++) {
            z_dict->data[i0 + z_dict->size[0] * n] += Sigma23z->data[i0 +
              Sigma23z->size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
          }
        }
      }
    } else {
      i0 = theta_new->A->size[1];
      n = theta_new->A->size[0];
      unnamed_idx_1 = (unsigned int)G_z->size[1];
      i1 = z_dict->size[0] * z_dict->size[1];
      z_dict->size[0] = n;
      z_dict->size[1] = (int)unnamed_idx_1;
      emxEnsureCapacity((emxArray__common *)z_dict, i1, sizeof(double));
      n = theta_new->A->size[0];
      i1 = z_dict->size[0] * z_dict->size[1];
      emxEnsureCapacity((emxArray__common *)z_dict, i1, sizeof(double));
      loop_ub = z_dict->size[1];
      for (i1 = 0; i1 < loop_ub; i1++) {
        br = z_dict->size[0];
        for (b_m = 0; b_m < br; b_m++) {
          z_dict->data[b_m + z_dict->size[0] * i1] = 0.0;
        }
      }

      i1 = theta_new->A->size[0];
      if ((i1 == 0) || (G_z->size[1] == 0)) {
      } else {
        i1 = theta_new->A->size[0];
        nx = i1 * (G_z->size[1] - 1);
        idx = 0;
        while ((n > 0) && (idx <= nx)) {
          i1 = idx + n;
          for (ic = idx; ic + 1 <= i1; ic++) {
            z_dict->data[ic] = 0.0;
          }

          idx += n;
        }

        br = 0;
        idx = 0;
        while ((n > 0) && (idx <= nx)) {
          ar = 0;
          i1 = br + i0;
          for (loop_ub = br; loop_ub + 1 <= i1; loop_ub++) {
            if (G_z->data[loop_ub] != 0.0) {
              ia = ar;
              b_m = idx + n;
              for (ic = idx; ic + 1 <= b_m; ic++) {
                ia++;
                z_dict->data[ic] += G_z->data[loop_ub] * Sigma23z->data[ia - 1];
              }
            }

            ar += n;
          }

          br += i0;
          idx += n;
        }
      }
    }

    loop_ub = z_dict->size[1];
    for (i0 = 0; i0 < loop_ub; i0++) {
      br = z_dict->size[0];
      for (n = 0; n < br; n++) {
        theta_new->A->data[(n + theta_new->A->size[0] * i0) + theta_new->A->
          size[0] * theta_new->A->size[1] * i] = z_dict->data[n + z_dict->size[0]
          * i0];
      }
    }

    i++;
  }

  emxFree_real_T(&b_A_ProdPart2);
  emxFree_creal_T(&r6);
  emxFree_real_T(&A_ProdPart2);
  emxFree_real_T(&A_ProdPart1);
  v = 0;
  emxInit_real_T1(&g_y, 2);
  emxInit_real_T1(&a, 2);
  emxInit_real_T2(&b_C_inv, 1);
  emxInit_real_T2(&c_C_inv, 1);
  emxInit_real_T2(&d_C_inv, 1);
  while (v <= (int)V - 1) {
    for (i = 0; i < (int)N; i++) {
      y = (T * (1.0 + (double)i) - T) + 1.0;
      b_y = T * (1.0 + (double)i);
      if (y > b_y) {
        i0 = 0;
        n = 0;
      } else {
        i0 = (int)y - 1;
        n = (int)b_y;
      }

      y = (T * (1.0 + (double)i) - T) + 1.0;
      b_y = T * (1.0 + (double)i);
      if (y > b_y) {
        i1 = 1;
        b_m = 1;
      } else {
        i1 = (int)y;
        b_m = (int)b_y + 1;
      }

      y = (T * (1.0 + (double)i) - T) + 1.0;
      b_y = T * (1.0 + (double)i);
      if (y > b_y) {
        i2 = 0;
        i3 = 0;
      } else {
        i2 = (int)y - 1;
        i3 = (int)b_y;
      }

      nx = a->size[0] * a->size[1];
      a->size[0] = 1;
      a->size[1] = n - i0;
      emxEnsureCapacity((emxArray__common *)a, nx, sizeof(double));
      loop_ub = n - i0;
      for (n = 0; n < loop_ub; n++) {
        a->data[a->size[0] * n] = Y[(i0 + n) + 60 * v];
      }

      loop_ub = C_inv->size[0];
      i0 = d_C_inv->size[0];
      d_C_inv->size[0] = loop_ub;
      emxEnsureCapacity((emxArray__common *)d_C_inv, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        d_C_inv->data[i0] = C_inv->data[i0 + C_inv->size[0] * i];
      }

      d_diag(d_C_inv, G_z);
      if ((a->size[1] == 1) || (G_z->size[0] == 1)) {
        i0 = g_y->size[0] * g_y->size[1];
        g_y->size[0] = 1;
        g_y->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)g_y, i0, sizeof(double));
        loop_ub = G_z->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          g_y->data[g_y->size[0] * i0] = 0.0;
          br = a->size[1];
          for (n = 0; n < br; n++) {
            g_y->data[g_y->size[0] * i0] += a->data[a->size[0] * n] * G_z->
              data[n + G_z->size[0] * i0];
          }
        }
      } else {
        k = a->size[1];
        unnamed_idx_1 = (unsigned int)G_z->size[1];
        i0 = g_y->size[0] * g_y->size[1];
        g_y->size[0] = 1;
        g_y->size[1] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)g_y, i0, sizeof(double));
        n = G_z->size[1] - 1;
        i0 = g_y->size[0] * g_y->size[1];
        g_y->size[0] = 1;
        emxEnsureCapacity((emxArray__common *)g_y, i0, sizeof(double));
        loop_ub = g_y->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          g_y->data[g_y->size[0] * i0] = 0.0;
        }

        if (G_z->size[1] != 0) {
          for (idx = 1; idx - 1 <= n; idx++) {
            for (ic = idx; ic <= idx; ic++) {
              g_y->data[ic - 1] = 0.0;
            }
          }

          br = 0;
          for (idx = 0; idx <= n; idx++) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (G_z->data[loop_ub] != 0.0) {
                ia = ar;
                for (ic = idx; ic + 1 <= idx + 1; ic++) {
                  ia++;
                  g_y->data[ic] += G_z->data[loop_ub] * a->data[ia - 1];
                }
              }

              ar++;
            }

            br += k;
          }
        }
      }

      i0 = nanid->size[0];
      nanid->size[0] = b_m - i1;
      emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
      loop_ub = b_m - i1;
      for (i0 = 0; i0 < loop_ub; i0++) {
        nanid->data[i0] = Y[((i1 + i0) + 60 * v) - 1];
      }

      if ((g_y->size[1] == 1) || (b_m - i1 == 1)) {
        y = 0.0;
        for (i0 = 0; i0 < g_y->size[1]; i0++) {
          y += g_y->data[g_y->size[0] * i0] * nanid->data[i0];
        }
      } else {
        y = 0.0;
        for (i0 = 0; i0 < g_y->size[1]; i0++) {
          y += g_y->data[g_y->size[0] * i0] * nanid->data[i0];
        }
      }

      nx = i3 - i2;
      loop_ub = i3 - i2;
      for (i0 = 0; i0 < loop_ub; i0++) {
        y_data[i0] = 2.0 * Y[(i2 + i0) + 60 * v];
      }

      loop_ub = C_inv->size[0];
      i0 = c_C_inv->size[0];
      c_C_inv->size[0] = loop_ub;
      emxEnsureCapacity((emxArray__common *)c_C_inv, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        c_C_inv->data[i0] = C_inv->data[i0 + C_inv->size[0] * i];
      }

      d_diag(c_C_inv, G_z);
      if ((nx == 1) || (G_z->size[0] == 1)) {
        i0 = g_y->size[0] * g_y->size[1];
        g_y->size[0] = 1;
        g_y->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)g_y, i0, sizeof(double));
        loop_ub = G_z->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          g_y->data[g_y->size[0] * i0] = 0.0;
          for (n = 0; n < nx; n++) {
            g_y->data[g_y->size[0] * i0] += y_data[n] * G_z->data[n + G_z->size
              [0] * i0];
          }
        }
      } else {
        unnamed_idx_1 = (unsigned int)G_z->size[1];
        i0 = g_y->size[0] * g_y->size[1];
        g_y->size[0] = 1;
        g_y->size[1] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)g_y, i0, sizeof(double));
        n = G_z->size[1] - 1;
        i0 = g_y->size[0] * g_y->size[1];
        g_y->size[0] = 1;
        emxEnsureCapacity((emxArray__common *)g_y, i0, sizeof(double));
        loop_ub = g_y->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          g_y->data[g_y->size[0] * i0] = 0.0;
        }

        if (G_z->size[1] != 0) {
          for (idx = 1; idx - 1 <= n; idx++) {
            for (ic = idx; ic <= idx; ic++) {
              g_y->data[ic - 1] = 0.0;
            }
          }

          br = 0;
          for (idx = 0; idx <= n; idx++) {
            ar = 0;
            i0 = br + nx;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (G_z->data[loop_ub] != 0.0) {
                ia = ar;
                for (ic = idx; ic + 1 <= idx + 1; ic++) {
                  ia++;
                  g_y->data[ic] += G_z->data[loop_ub] * y_data[ia - 1];
                }
              }

              ar++;
            }

            br += nx;
          }
        }
      }

      loop_ub = theta_new->A->size[0];
      br = theta_new->A->size[1];
      i0 = G_z->size[0] * G_z->size[1];
      G_z->size[0] = loop_ub;
      G_z->size[1] = br;
      emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
      for (i0 = 0; i0 < br; i0++) {
        for (n = 0; n < loop_ub; n++) {
          G_z->data[n + G_z->size[0] * i0] = theta_new->A->data[(n +
            theta_new->A->size[0] * i0) + theta_new->A->size[0] * theta_new->
            A->size[1] * i];
        }
      }

      guard1 = false;
      if (g_y->size[1] == 1) {
        guard1 = true;
      } else {
        i0 = theta_new->A->size[0];
        if (i0 == 1) {
          guard1 = true;
        } else {
          k = g_y->size[1];
          i0 = theta_new->A->size[1];
          n = a->size[0] * a->size[1];
          a->size[0] = 1;
          a->size[1] = i0;
          emxEnsureCapacity((emxArray__common *)a, n, sizeof(double));
          i0 = theta_new->A->size[1] - 1;
          n = a->size[0] * a->size[1];
          a->size[0] = 1;
          emxEnsureCapacity((emxArray__common *)a, n, sizeof(double));
          loop_ub = a->size[1];
          for (n = 0; n < loop_ub; n++) {
            a->data[a->size[0] * n] = 0.0;
          }

          n = theta_new->A->size[1];
          if (n != 0) {
            for (idx = 1; idx - 1 <= i0; idx++) {
              for (ic = idx; ic <= idx; ic++) {
                a->data[ic - 1] = 0.0;
              }
            }

            br = 0;
            for (idx = 0; idx <= i0; idx++) {
              ar = 0;
              n = br + k;
              for (loop_ub = br; loop_ub + 1 <= n; loop_ub++) {
                if (G_z->data[loop_ub] != 0.0) {
                  ia = ar;
                  for (ic = idx; ic + 1 <= idx + 1; ic++) {
                    ia++;
                    a->data[ic] += G_z->data[loop_ub] * g_y->data[ia - 1];
                  }
                }

                ar++;
              }

              br += k;
            }
          }
        }
      }

      if (guard1) {
        i0 = a->size[0] * a->size[1];
        a->size[0] = 1;
        a->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)a, i0, sizeof(double));
        loop_ub = G_z->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          a->data[a->size[0] * i0] = 0.0;
          br = g_y->size[1];
          for (n = 0; n < br; n++) {
            a->data[a->size[0] * i0] += g_y->data[g_y->size[0] * n] * G_z->
              data[n + G_z->size[0] * i0];
          }
        }
      }

      loop_ub = subICmean->size[0];
      i0 = nanid->size[0];
      nanid->size[0] = loop_ub;
      emxEnsureCapacity((emxArray__common *)nanid, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        nanid->data[i0] = subICmean->data[(i0 + subICmean->size[0] * i) +
          subICmean->size[0] * subICmean->size[1] * v];
      }

      guard1 = false;
      if (a->size[1] == 1) {
        guard1 = true;
      } else {
        i0 = subICmean->size[0];
        if (i0 == 1) {
          guard1 = true;
        } else {
          b_y = 0.0;
          for (i0 = 0; i0 < a->size[1]; i0++) {
            b_y += a->data[a->size[0] * i0] * nanid->data[i0];
          }
        }
      }

      if (guard1) {
        b_y = 0.0;
        for (i0 = 0; i0 < a->size[1]; i0++) {
          b_y += a->data[a->size[0] * i0] * nanid->data[i0];
        }
      }

      loop_ub = theta_new->A->size[0];
      br = theta_new->A->size[1];
      i0 = Sigma23z->size[0] * Sigma23z->size[1];
      Sigma23z->size[0] = br;
      Sigma23z->size[1] = loop_ub;
      emxEnsureCapacity((emxArray__common *)Sigma23z, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        for (n = 0; n < br; n++) {
          Sigma23z->data[n + Sigma23z->size[0] * i0] = theta_new->A->data[(i0 +
            theta_new->A->size[0] * n) + theta_new->A->size[0] * theta_new->
            A->size[1] * i];
        }
      }

      loop_ub = C_inv->size[0];
      i0 = b_C_inv->size[0];
      b_C_inv->size[0] = loop_ub;
      emxEnsureCapacity((emxArray__common *)b_C_inv, i0, sizeof(double));
      for (i0 = 0; i0 < loop_ub; i0++) {
        b_C_inv->data[i0] = C_inv->data[i0 + C_inv->size[0] * i];
      }

      d_diag(b_C_inv, G_z);
      if ((Sigma23z->size[1] == 1) || (G_z->size[0] == 1)) {
        i0 = c_y->size[0] * c_y->size[1];
        c_y->size[0] = Sigma23z->size[0];
        c_y->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        loop_ub = Sigma23z->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            c_y->data[i0 + c_y->size[0] * n] = 0.0;
            nx = Sigma23z->size[1];
            for (i1 = 0; i1 < nx; i1++) {
              c_y->data[i0 + c_y->size[0] * n] += Sigma23z->data[i0 +
                Sigma23z->size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
            }
          }
        }
      } else {
        k = Sigma23z->size[1];
        unnamed_idx_0 = (unsigned int)Sigma23z->size[0];
        unnamed_idx_1 = (unsigned int)G_z->size[1];
        i0 = c_y->size[0] * c_y->size[1];
        c_y->size[0] = (int)unnamed_idx_0;
        c_y->size[1] = (int)unnamed_idx_1;
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        b_m = Sigma23z->size[0];
        i0 = c_y->size[0] * c_y->size[1];
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        loop_ub = c_y->size[1];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = c_y->size[0];
          for (n = 0; n < br; n++) {
            c_y->data[n + c_y->size[0] * i0] = 0.0;
          }
        }

        if ((Sigma23z->size[0] == 0) || (G_z->size[1] == 0)) {
        } else {
          nx = Sigma23z->size[0] * (G_z->size[1] - 1);
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            i0 = idx + b_m;
            for (ic = idx; ic + 1 <= i0; ic++) {
              c_y->data[ic] = 0.0;
            }

            idx += b_m;
          }

          br = 0;
          idx = 0;
          while ((b_m > 0) && (idx <= nx)) {
            ar = 0;
            i0 = br + k;
            for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
              if (G_z->data[loop_ub] != 0.0) {
                ia = ar;
                n = idx + b_m;
                for (ic = idx; ic + 1 <= n; ic++) {
                  ia++;
                  c_y->data[ic] += G_z->data[loop_ub] * Sigma23z->data[ia - 1];
                }
              }

              ar += b_m;
            }

            br += k;
            idx += b_m;
          }
        }
      }

      loop_ub = theta_new->A->size[0];
      br = theta_new->A->size[1];
      i0 = G_z->size[0] * G_z->size[1];
      G_z->size[0] = loop_ub;
      G_z->size[1] = br;
      emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
      for (i0 = 0; i0 < br; i0++) {
        for (n = 0; n < loop_ub; n++) {
          G_z->data[n + G_z->size[0] * i0] = theta_new->A->data[(n +
            theta_new->A->size[0] * i0) + theta_new->A->size[0] * theta_new->
            A->size[1] * i];
        }
      }

      guard1 = false;
      if (c_y->size[1] == 1) {
        guard1 = true;
      } else {
        i0 = theta_new->A->size[0];
        if (i0 == 1) {
          guard1 = true;
        } else {
          k = c_y->size[1];
          i0 = theta_new->A->size[1];
          unnamed_idx_0 = (unsigned int)c_y->size[0];
          n = z_dict->size[0] * z_dict->size[1];
          z_dict->size[0] = (int)unnamed_idx_0;
          z_dict->size[1] = i0;
          emxEnsureCapacity((emxArray__common *)z_dict, n, sizeof(double));
          b_m = c_y->size[0];
          i0 = z_dict->size[0] * z_dict->size[1];
          emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
          loop_ub = z_dict->size[1];
          for (i0 = 0; i0 < loop_ub; i0++) {
            br = z_dict->size[0];
            for (n = 0; n < br; n++) {
              z_dict->data[n + z_dict->size[0] * i0] = 0.0;
            }
          }

          if (c_y->size[0] == 0) {
          } else {
            i0 = theta_new->A->size[1];
            if (i0 == 0) {
            } else {
              i0 = theta_new->A->size[1] - 1;
              nx = c_y->size[0] * i0;
              idx = 0;
              while ((b_m > 0) && (idx <= nx)) {
                i0 = idx + b_m;
                for (ic = idx; ic + 1 <= i0; ic++) {
                  z_dict->data[ic] = 0.0;
                }

                idx += b_m;
              }

              br = 0;
              idx = 0;
              while ((b_m > 0) && (idx <= nx)) {
                ar = 0;
                i0 = br + k;
                for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
                  if (G_z->data[loop_ub] != 0.0) {
                    ia = ar;
                    n = idx + b_m;
                    for (ic = idx; ic + 1 <= n; ic++) {
                      ia++;
                      z_dict->data[ic] += G_z->data[loop_ub] * c_y->data[ia - 1];
                    }
                  }

                  ar += b_m;
                }

                br += k;
                idx += b_m;
              }
            }
          }
        }
      }

      if (guard1) {
        i0 = z_dict->size[0] * z_dict->size[1];
        z_dict->size[0] = c_y->size[0];
        z_dict->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)z_dict, i0, sizeof(double));
        loop_ub = c_y->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            z_dict->data[i0 + z_dict->size[0] * n] = 0.0;
            nx = c_y->size[1];
            for (i1 = 0; i1 < nx; i1++) {
              z_dict->data[i0 + z_dict->size[0] * n] += c_y->data[i0 + c_y->
                size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
            }
          }
        }
      }

      loop_ub = subICvar->size[0];
      br = subICvar->size[1];
      i0 = G_z->size[0] * G_z->size[1];
      G_z->size[0] = loop_ub;
      G_z->size[1] = br;
      emxEnsureCapacity((emxArray__common *)G_z, i0, sizeof(double));
      for (i0 = 0; i0 < br; i0++) {
        for (n = 0; n < loop_ub; n++) {
          G_z->data[n + G_z->size[0] * i0] = subICvar->data[((n + subICvar->
            size[0] * i0) + subICvar->size[0] * subICvar->size[1] * i) +
            subICvar->size[0] * subICvar->size[1] * subICvar->size[2] * v];
        }
      }

      guard1 = false;
      if (z_dict->size[1] == 1) {
        guard1 = true;
      } else {
        i0 = subICvar->size[0];
        if (i0 == 1) {
          guard1 = true;
        } else {
          k = z_dict->size[1];
          i0 = subICvar->size[1];
          unnamed_idx_0 = (unsigned int)z_dict->size[0];
          n = c_y->size[0] * c_y->size[1];
          c_y->size[0] = (int)unnamed_idx_0;
          c_y->size[1] = i0;
          emxEnsureCapacity((emxArray__common *)c_y, n, sizeof(double));
          b_m = z_dict->size[0];
          i0 = c_y->size[0] * c_y->size[1];
          emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
          loop_ub = c_y->size[1];
          for (i0 = 0; i0 < loop_ub; i0++) {
            br = c_y->size[0];
            for (n = 0; n < br; n++) {
              c_y->data[n + c_y->size[0] * i0] = 0.0;
            }
          }

          if (z_dict->size[0] == 0) {
          } else {
            i0 = subICvar->size[1];
            if (i0 == 0) {
            } else {
              i0 = subICvar->size[1] - 1;
              nx = z_dict->size[0] * i0;
              idx = 0;
              while ((b_m > 0) && (idx <= nx)) {
                i0 = idx + b_m;
                for (ic = idx; ic + 1 <= i0; ic++) {
                  c_y->data[ic] = 0.0;
                }

                idx += b_m;
              }

              br = 0;
              idx = 0;
              while ((b_m > 0) && (idx <= nx)) {
                ar = 0;
                i0 = br + k;
                for (loop_ub = br; loop_ub + 1 <= i0; loop_ub++) {
                  if (G_z->data[loop_ub] != 0.0) {
                    ia = ar;
                    n = idx + b_m;
                    for (ic = idx; ic + 1 <= n; ic++) {
                      ia++;
                      c_y->data[ic] += G_z->data[loop_ub] * z_dict->data[ia - 1];
                    }
                  }

                  ar += b_m;
                }

                br += k;
                idx += b_m;
              }
            }
          }
        }
      }

      if (guard1) {
        i0 = c_y->size[0] * c_y->size[1];
        c_y->size[0] = z_dict->size[0];
        c_y->size[1] = G_z->size[1];
        emxEnsureCapacity((emxArray__common *)c_y, i0, sizeof(double));
        loop_ub = z_dict->size[0];
        for (i0 = 0; i0 < loop_ub; i0++) {
          br = G_z->size[1];
          for (n = 0; n < br; n++) {
            c_y->data[i0 + c_y->size[0] * n] = 0.0;
            nx = z_dict->size[1];
            for (i1 = 0; i1 < nx; i1++) {
              c_y->data[i0 + c_y->size[0] * n] += z_dict->data[i0 + z_dict->
                size[0] * i1] * G_z->data[i1 + G_z->size[0] * n];
            }
          }
        }
      }

      theta_new->sigma1_sq = ((theta_new->sigma1_sq + y) - b_y) + trace(c_y);
    }

    v++;
  }

  emxFree_real_T(&d_C_inv);
  emxFree_real_T(&c_C_inv);
  emxFree_real_T(&b_C_inv);
  emxFree_real_T(&c_y);
  emxFree_real_T(&a);
  emxFree_real_T(&g_y);
  emxFree_real_T(&nanid);
  emxFree_real_T(&Sigma23z);
  emxFree_real_T(&G_z);
  emxFree_real_T(&z_dict);
  emxFree_real_T(&C_inv);
  theta_new->sigma1_sq *= 1.0 / (N * T * V);

  /* %% end of function */
  *err = 0.0;
}

/* End of code generation (UpdateThetaBetaAprx_LargeData.c) */
