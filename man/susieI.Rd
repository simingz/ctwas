% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ctwas_susieI.R
\name{susieI}
\alias{susieI}
\title{SuSiE iteraitve}
\usage{
susieI(pgenfs, exprfs, Y, regionlist, niter = 20, L = 1,
  group_prior = NULL, group_prior_var = NULL,
  estimate_group_prior = T, estimate_group_prior_var = T,
  use_null_weight = T, coverage = 0.95, standardize = T, ncore = 1,
  outputdir = getwd(), outname = NULL)
}
\arguments{
\item{standardize}{True/False. Follows susie convention: If
standardize = TRUE, standardize the columns of X to unit variance
 prior to fitting. Note that scaled_prior_variance' specifies the prior
 on the coefficients of X after standardization (if it is performed).
 If you do not standardize, you may need to think more carefully about
 specifying scaled_prior_variance. Whatever your choice, the coefficients
 returned by coef are given for X on the original input scale. Any
 column of X that has zero variance is not standardized, but left
 as is.}
}
\description{
SuSiE iteraitve
}
