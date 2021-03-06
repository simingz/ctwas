#' Prepare .pvar file
#' @param pgenf pgen file
#'  .pvar file format: https://www.cog-genomics.org/plink/2.0/formats#pvar
#' @return corresponding pvar file
#'
#' @importFrom tools file_ext file_path_sans_ext
#' @export
prep_pvar <- function(pgenf, outputdir = getwd()){

  if (file_ext(pgenf) == "pgen"){
    pvarf <- paste0(file_path_sans_ext(pgenf), ".pvar")
    pvarf2 <-  paste0(outputdir, basename(file_path_sans_ext(pgenf)), ".hpvar")

    # pgenlib can't read pvar without header, check if header present
    firstl <- read.table(file = pvarf, header = F, comment.char = '',
                         nrows = 1, stringsAsFactors = F)

    if (substr(firstl[1,1],1,1) == '#') {
      pvarfout <- pvarf
    } else {
      pvarfout <- pvarf2

      if (!file.exists(pvarf2)) {
        pvar <- data.table::fread(pvarf, header = F)

        if (ncol(pvar) == 6) {
          colnames(pvar) <- c('#CHROM', 'ID', 'CM', 'POS', 'ALT', 'REF')
        } else if (ncol(pvar) == 5){
          colnames(pvar) <- c('#CHROM', 'ID', 'POS', 'ALT', 'REF')
        } else {
          stop(".pvar file has incorrect format")
        }

        data.table::fwrite(pvar, file = pvarf2 , sep="\t", quote = F)
      }
    }

  } else if (file_ext(pgenf) == "bed"){
    # .bim file has no header
    pvarf <- paste0(file_path_sans_ext(pgenf), ".bim")
    pvarf2 <-  file.path(outputdir, paste0(basename(file_path_sans_ext(pgenf)), ".hbim"))

    if (!file.exists(pvarf2)){
      pvar <- data.table::fread(pvarf, header = F)
      colnames(pvar) <- c('#CHROM', 'ID', 'CM', 'POS', 'ALT', 'REF')
      data.table::fwrite(pvar, file = pvarf2 , sep="\t", quote = F)
    }
    pvarfout <- pvarf2
  } else {
    stop("Unrecognized genotype input format")
  }

  pvarfout
}

#' Read .pvar file into R
#' @param pvarf .pvar file or .bim file with have proper
#'  .pvar file format: https://www.cog-genomics.org/plink/2.0/formats#pvar
#'
#' @return A data.table. variant info
#' @export
read_pvar <- function(pvarf){

  pvardt <- data.table::fread(pvarf, skip = "#CHROM")
  pvardt <- dplyr::rename(pvardt, "chrom" = "#CHROM", "pos" = "POS",
                "alt" = "ALT", "ref" = "REF", "id" = "ID")
  pvardt <- pvardt[, c("chrom", "id", "pos", "alt", "ref")]
  pvardt
}

#' Read .pgen file into R
#' @param pgenf .pgen file or .bed file
#' @param pvarf .pvar file or .bim file with have proper
#'  header.  Matching `pgenf`.
#' @return  A matrix of allele count for each variant (columns) in each sample
#'  (rows). ALT allele in pvar file is counted (A1 allele in .bim file is the ALT
#'   allele).
#'
#' @importFrom pgenlibr NewPvar
#' @importFrom pgenlibr NewPgen
#' @importFrom tools file_ext file_path_sans_ext
#'
#' @export
#'
prep_pgen <- function(pgenf, pvarf){

  pvar <- pgenlibr::NewPvar(pvarf)

  if (file_ext(pgenf) == "pgen"){
    pgen <- pgenlibr::NewPgen(pgenf, pvar = pvar)

  } else if (file_ext(pgenf) == "bed"){
    famf <- paste0(file_path_sans_ext(pgenf), ".fam")
    fam <- data.table::fread(famf, header = F)
    raw_s_ct <- nrow(fam)
    pgen <- pgenlibr::NewPgen(pgenf, pvar = pvar, raw_sample_ct = raw_s_ct)

  } else{
    stop("unrecognized input")
  }

  pgen
}

#' Read pgen file into R
#' @param variantidx variant index. If NULL, all variants will be extracted.
#' @return A matrix, columns are allele count for each SNP, rows are
#'  for each sample.
#' @importFrom pgenlibr GetVariantCt
#' @importFrom pgenlibr ReadList
#' @export
read_pgen <- function(pgen, variantidx = NULL, meanimpute = F ){
  if (is.null(variantidx)){
    variantidx <- 1: pgenlibr::GetVariantCt(pgen)}

  pgenlibr::ReadList(pgen,
                     variant_subset = variantidx,
                     meanimpute = meanimpute)
}


#' Prepare .exprvar file
#' @return corresponding exprvar file
#'
#' @importFrom tools file_ext file_path_sans_ext
#' @export
prep_exprvar <- function(exprf){
  if (file_ext(exprf) == "gz"){
    exprf <- file_path_sans_ext(exprf)
  }
  exprvarf <- paste0(exprf, "var")
  exprvarf
}

#' Read .exprvar file into R
#' @return A data.table. variant info
#' @export
read_exprvar <- function(exprvarf){

  exprvar <- try(data.table::fread(exprvarf, header = T))

  if (inherits(exprvar, "try-error")){
    exprvar <-  setNames(data.table(matrix(nrow = 0, ncol = 4)),
                         c("chrom", "id", "p0", "p1"))
  }
  exprvar
}

#' Read .expr file into R
#' @param variantidx variant index. If NULL, all variants will be extracted.
#' @return A matrix, columns are imputed expression for each gene, rows are
#'  for each sample.
#' @export
read_expr <- function(exprf, variantidx = NULL){
  if (!is.null(variantidx) & length(variantidx)==0){
    return(NULL)
  } else{
    return(as.matrix(data.table::fread(exprf, header = F,
                                       select = variantidx)))
  }
}


#' read variant information associated with a LD R matrix .RDS file.
#'
#' @return a data frame with columns: "chrom", "id", "pos", "alt", "ref". "alt" is
#' the coded allele
#'
#' @importFrom tools file_ext file_path_sans_ext
read_ld_Rvar_RDS <- function(ld_RDSf){
  ld_Rvarf <- paste0(file_path_sans_ext(ld_RDSf), ".Rvar")
  ld_Rvar <- data.table::fread(ld_Rvarf, header = T)
  target_header <- c("chrom", "id", "pos", "alt", "ref")
  if (all(target_header %in% colnames(ld_Rvar))){
      return(ld_Rvar)
  } else {
    stop("The .Rvar file needs to contain the following columns: ",
         paste(target_header, collapse = " "))
  }
}


#' @param ld_R_dir The directory that contains all ld R mattrices.
#' the ld R matrices should not have overlapping positions.
#'
#' @return A vector of the `ld_Rf` file names. The function will write one `ld_Rf` file
#' for each chromosome, so the vector has length 22. The `ld_Rf` file has the following
#' columns: chr region_name start stop RDS_file.
write_ld_Rf <- function(ld_R_dir, outname = outname , outputdir = getwd()){
  ld_RDSfs <- list.files(path = ld_R_dir, pattern = "\\.RDS$", full.names = T)
  ldinfolist <- list()
  for (ld_RDSf in ld_RDSfs){
    Rvar <- read_ld_Rvar_RDS(ld_RDSf)
    chrom <- unique(Rvar$chrom)
    if (length(chrom) != 1){
      stop("R matrix on multiple chromosomes,
           can't handle this. Need to be on one chromosome:", ld_RDSf)
    }
    start <- min(Rvar$pos)
    stop <- max(Rvar$pos) + 1
    ldinfolist[[ld_RDSf]] <- c(chrom, start, stop, ld_RDSf)
  }
  ldinfo <- do.call(rbind, ldinfolist)
  colnames(ldinfo) <- c("chrom", "start", "stop", "RDS_file")
  rownames(ldinfo) <- NULL
  ldinfo <- data.frame(ldinfo, stringsAsFactors = F)
  ldinfo <- transform(ldinfo, chrom = as.numeric(chrom),
                      start = as.numeric(start),
                      stop = as.numeric(stop))

  ld_Rfs <- vector()
  for (b in 1:22){
    ldinfo.b <- ldinfo[ldinfo$chrom == b, , drop = F]
    if (nrow(ldinfo.b) == 0){
      stop("no region on chromosome ", b, "at least one is required.")
    }
    ldinfo.b <- ldinfo.b[order(ldinfo.b$start),]
    ldinfo.b$region_name <- 1:nrow(ldinfo.b)
    ld_Rf <- file.path(outputdir, paste0(outname, "_ld_R_chr", b, ".txt"))
    write.table(ldinfo.b, file= ld_Rf,
                row.names=F, col.names=T, sep="\t", quote = F)
    ld_Rfs[b] <- ld_Rf
  }
  ld_Rfs
}

#' read variant information for all ld mattrices in `ld_Rf`.
#' @return a data frame with columns: "chrom", "id", "pos", "alt", "ref"
read_ld_Rvar <- function(ld_Rf){
  Rinfo <- data.table::fread(ld_Rf, header = T)
  ld_Rvar <- do.call(rbind, lapply(Rinfo$RDS_file, read_ld_Rvar_RDS))
  ld_Rvar
}

read_weight_fusion <- function(weight, chrom, ld_snpinfo, z_snp = NULL, method = "lasso", harmonize = T){
  exprlist <- list()
  qclist <- list()
  wgtdir <- dirname(weight)
  wgtposfile <- file.path(wgtdir, paste0(basename(weight), ".pos"))

  wgtpos <- read.table(wgtposfile, header = T, stringsAsFactors = F)
  wgtpos <- transform(wgtpos,
                      ID = ifelse(duplicated(ID) | duplicated(ID, fromLast = TRUE),
                                  paste(ID, ave(ID, ID, FUN = seq_along), sep = "_ID"), ID))
  loginfo("number of genes with weights provided: %s", nrow(wgtpos))

  wgtpos <- wgtpos[wgtpos$CHR==chrom,]
  loginfo("number of genes on chromosome %s: %s", chrom, nrow(wgtpos))

  loginfo("collecting gene weight information ...")
  if (nrow(wgtpos) > 0){
    for (i in 1:nrow(wgtpos)) {
      # for (i in 1:2) {
      wf <- file.path(wgtdir, wgtpos[i, "WGT"])
      load(wf)
      gname <- wgtpos[i, "ID"]
      if (isTRUE(harmonize)) {
        w <- harmonize_wgt_ld(wgt.matrix, snps, ld_snpinfo)
        wgt.matrix <- w[["wgt"]]
        snps <- w[["snps"]]
      }
      g.method = method
      if (g.method == "best") {
        g.method = names(which.max(cv.performance["rsq",]))
      }
      if (!(g.method %in% names(cv.performance[1, ])))
        next
      wgt.matrix <- wgt.matrix[abs(wgt.matrix[, g.method]) > 0, , drop = F]
      wgt.matrix <- wgt.matrix[complete.cases(wgt.matrix), , drop = F]
      if (nrow(wgt.matrix) == 0)
        next

      if (is.null(z_snp)){
        snpnames <- intersect(rownames(wgt.matrix), ld_snpinfo$id)
      } else{
        snpnames <- Reduce(intersect, list(rownames(wgt.matrix), ld_snpinfo$id, z_snp$id))
      }

      if (length(snpnames) == 0)
        next
      wgt.idx <- match(snpnames, rownames(wgt.matrix))
      wgt <- wgt.matrix[wgt.idx, g.method, drop = F]

      p0 <-  min(snps[snps[, "id"] %in% snpnames, "pos"])
      p1 <- max(snps[snps[, "id"] %in% snpnames, "pos"])

      exprlist[[gname]] <- list("chrom" = chrom,
                                "p0" = p0,
                                "p1" = p1,
                                "wgt" = wgt)

      nwgt <- nrow(wgt.matrix)
      nmiss <- nrow(wgt.matrix) - length(snpnames)
      qclist[[gname]] <- list("n" = nwgt,
                              "nmiss" = nmiss,
                              "missrate" = nwgt/nmiss)

    }
  }
  return(list("exprlist" = exprlist, "qclist" = qclist))
}

read_weight_predictdb <- function(weight, chrom, ld_snpinfo, z_snp = NULL, harmonize = T){
  exprlist <- list()
  qclist <- list()

  sqlite <- RSQLite::dbDriver("SQLite")
  db = RSQLite::dbConnect(sqlite,weight)

  ## convenience query function
  query <- function(...) RSQLite::dbGetQuery(db, ...)

  gnames <- unique(query('select gene from weights')[,1])
  loginfo("number of genes with weights provided: %s",
          length(gnames))

  loginfo("collecting gene weight information ...")
  for (gname in gnames){
    wgt <- query('select * from weights where gene = ?', params = list(gname))
    wgt.matrix <- as.matrix(wgt[, "weight", drop = F])
    rownames(wgt.matrix) <- wgt$rsid
    chrpos <- do.call(rbind, strsplit(wgt$varID, "_"))
    snps <- data.frame(gsub("chr", "", chrpos[,1]), wgt$rsid, "0", chrpos[,2],
                       wgt$eff_allele, wgt$ref_allele, stringsAsFactors = F)
    colnames(snps) <- c("chrom", "id", "cm", "pos", "alt", "ref")
    snps$chrom <- as.integer(snps$chrom)
    snps$pos <- as.integer(snps$pos)

    if (isTRUE(harmonize)) {
      w <- harmonize_wgt_ld(wgt.matrix, snps, ld_snpinfo)
      wgt.matrix <- w[["wgt"]]
      snps <- w[["snps"]]
    }
    g.method = "weight"
    wgt.matrix <- wgt.matrix[abs(wgt.matrix[, g.method]) > 0, , drop = F]
    wgt.matrix <- wgt.matrix[complete.cases(wgt.matrix), , drop = F]
    if (nrow(wgt.matrix) == 0)
      next

    if (is.null(z_snp)){
      snpnames <- intersect(rownames(wgt.matrix), ld_snpinfo$id)
    } else{
      snpnames <- Reduce(intersect, list(rownames(wgt.matrix), ld_snpinfo$id, z_snp$id))
    }

    if (length(snpnames) == 0)
      next

    wgt.idx <- match(snpnames, rownames(wgt.matrix))
    wgt <- wgt.matrix[wgt.idx, g.method, drop = F]

    p0 <-  min(snps[snps[, "id"] %in% snpnames, "pos"])
    p1 <- max(snps[snps[, "id"] %in% snpnames, "pos"])

    exprlist[[gname]] <- list("chrom" = chrom,
                              "p0" = p0,
                              "p1" = p1,
                              "wgt" = wgt)

    nwgt <- nrow(wgt.matrix)
    nmiss <- nrow(wgt.matrix) - length(snpnames)
    qclist[[gname]] <- list("n" = nwgt,
                            "nmiss" = nmiss,
                            "missrate" = nwgt/nmiss)
  }

  RSQLite::dbDisconnect(db)
  return(list("exprlist" = exprlist, "qclist" = qclist))
}



