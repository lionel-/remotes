
#' Install a package from a local file
#'
#' This function is vectorised so you can install multiple packages in
#' a single command.
#'
#' @param path path to local directory, or compressed file (tar, zip, tar.gz
#'   tar.bz2, tgz2 or tbz)
#' @inheritParams install_url
#' @inheritParams install_github
#' @export
#' @family package installation
#' @examples
#' \dontrun{
#' dir <- tempfile()
#' dir.create(dir)
#' pkg <- download.packages("testthat", dir, type = "source")
#' install_local(pkg[, 2])
#' }

install_local <- function(path = ".", subdir = NULL,
                           dependencies = NA,
                           upgrade = c("default", "ask", "always", "never"),
                           force = FALSE,
                           quiet = FALSE,
                           build = !is_binary_pkg(path),
                           build_opts = c("--no-resave-data", "--no-manual", "--no-build-vignettes"),
                           build_manual = FALSE, build_vignettes = FALSE,
                           repos = getOption("repos"),
                           type = getOption("pkgType"),
                           ...) {

  remotes <- lapply(path, local_remote, subdir = subdir)
  install_remotes(remotes,
                  dependencies = dependencies,
                  upgrade = upgrade,
                  force = force,
                  quiet = quiet,
                  build = build,
                  build_opts = build_opts,
                  build_manual = build_manual,
                  build_vignettes = build_vignettes,
                  repos = repos,
                  type = type,
                  ...)
}

local_remote <- function(path, subdir = NULL, branch = NULL, args = character(0), ...) {
  remote("local",
    path = normalizePath(path),
    subdir = subdir
  )
}

#' @export
remote_download.local_remote <- function(x, quiet = FALSE) {
  # Already downloaded - just need to copy to tempdir()
  bundle <- tempfile()
  dir.create(bundle)
  suppressWarnings(
    res <- file.copy(x$path, bundle, recursive = TRUE)
  )
  if (!all(res)) {
    stop("Could not copy `", x$path, "` to `", bundle, "`", call. = FALSE)
  }

  # file.copy() creates directory inside of bundle
  dir(bundle, full.names = TRUE)[1]
}

#' @export
remote_metadata.local_remote <- function(x, bundle = NULL, source = NULL, sha = NULL) {
  list(
    RemoteType = "local",
    RemoteUrl = x$path,
    RemoteSubdir = x$subdir
  )
}

#' @export
remote_package_name.local_remote <- function(remote, ...) {
  is_tarball <- !dir.exists(remote$path)
  if (is_tarball) {
    # Assume the name is the name of the tarball
    return(sub("_.*$", "", basename(remote$path)))
  }
  description_path <- file.path(remote$path, "DESCRIPTION")

  read_dcf(description_path)$Package
}

#' @export
remote_sha.local_remote <- function(remote, ...) {
  is_tarball <- !dir.exists(remote$path)
  if (is_tarball) {
    return(NA_character_)
  }

  read_dcf(file.path(remote$path, "DESCRIPTION"))$Version
}

#' @export
format.local_remote <- function(x, ...) {
  "local"
}
