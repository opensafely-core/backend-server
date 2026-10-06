#!/usr/bin/env python3
r"""
Keep a local Docker image reference in sync with a remote reference by pulling the
remote image and updating the local reference to match, but only if passes the required
signature and provenance attestation checks.

Example:

    ./sync_verified_image.py \
      --source ghcr.io/opensafely-core/job-runner:test-fixture-signed \
      --target local/job-runner:verified \
      --enforce-github-repo opensafely-core/job-runner \
      --enforce-branch test-fixtures
"""

import argparse
import json
import re
import shlex
import subprocess
from pathlib import Path


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--source",
        required=True,
        help="source Docker image reference",
    )
    parser.add_argument(
        "--target",
        required=True,
        help="local image reference to create after verification",
    )
    parser.add_argument(
        "--enforce-github-repo",
        required=True,
        help="GitHub repository expected in the signing certificate (OWNER/REPO)",
    )
    parser.add_argument(
        "--enforce-branch",
        required=True,
        help="source branch expected in the signing certificate",
    )
    parser.add_argument(
        "--trusted-root",
        type=Path,
        required=False,
        help="path to trusted_root.json",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="only produce output on error or update",
    )

    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    log = print if not args.quiet else lambda _: None
    pull_verify_retag(**vars(args), log=log)


def pull_verify_retag(
    *,
    source,
    target,
    enforce_github_repo,
    enforce_branch,
    trusted_root,
    quiet,
    log=print,
):
    log(f"Running:\n  docker pull {source}")
    run("docker", "pull", "--quiet", source)

    source_id = get_image_id(source)
    target_id = get_image_id(target, none_if_missing=True)
    if source_id == target_id:
        log(f"Nothing to do; image IDs already match:\n  {source}\n  {target}")
        return

    source_digest = get_image_digest(source, source_id)

    print(f"Verifying new image:\n  ID: {source_id}\n  Digest: {source_digest}")
    verify_image(
        image_digest=source_digest,
        github_repo=enforce_github_repo,
        branch=enforce_branch,
        trusted_root=trusted_root,
    )

    print(f"Image verified; updating local image reference:\n  {target}")
    run("docker", "tag", source_id, target)


def verify_image(*, image_digest, github_repo, branch, trusted_root=None):
    git_ref = f"refs/heads/{branch}"
    # We don't assert on the specific workflow that created the signatures, just the
    # repository and branch to which it belongs
    identity_regexp = (
        "^"
        + re.escape(f"https://github.com/{github_repo}/.github/workflows/")
        + r"[^@]+"
        + re.escape(f"@{git_ref}")
        + "$"
    )

    common = [
        "--new-bundle-format",
        "--certificate-oidc-issuer",
        "https://token.actions.githubusercontent.com",
        "--certificate-identity-regexp",
        identity_regexp,
        "--certificate-github-workflow-repository",
        github_repo,
        "--certificate-github-workflow-ref",
        git_ref,
    ]
    if trusted_root:
        common.extend(["--trusted-root", trusted_root])

    # At present the workflow which attests to the image's provenance and the one which
    # signs it as ready for release are the same, so the below two commands effectively
    # verify the same thing twice. However this may not always be the case so it's good
    # to have both steps in place.
    run_cosign(
        "verify-attestation",
        "--type",
        "https://slsa.dev/provenance/v1",
        *common,
        image_digest,
    )
    run_cosign(
        "verify",
        *common,
        image_digest,
    )


def get_image_id(image_ref, none_if_missing=False):
    try:
        result = run("docker", "image", "inspect", "--format", "{{.Id}}", image_ref)
    except subprocess.CalledProcessError as exc:
        if none_if_missing and "No such image" in (exc.stderr or ""):
            return
        raise
    return result.stdout.strip()


def get_image_digest(image_ref, image_id):
    result = run(
        "docker", "image", "inspect", "--format", "{{json .RepoDigests}}", image_id
    )
    digests = json.loads(result.stdout)
    image_name = image_ref.rpartition(":")[0]
    matching_digests = [d for d in digests if d.startswith(f"{image_name}@")]
    assert len(matching_digests) == 1, (
        f"Expected exactly 1 match: {matching_digests!r} in {digests!r}"
    )
    return matching_digests[0]


def run_cosign(*args):
    try:
        return run("cosign", *args)
    except subprocess.CalledProcessError as exc:
        print(
            f"Image verification failed:\n{prettify_command(exc.cmd)}\n\n{exc.stderr}"
        )
        raise SystemExit(2)


def run(*command):
    try:
        return subprocess.run(command, check=True, text=True, capture_output=True)
    except subprocess.CalledProcessError as exc:
        # We currently have to support older Python versions without this feature. It's
        # non-critical but a useful debugging aid so we leave it in.
        if hasattr(exc, "add_note"):
            exc.add_note(f"\nstdout:\n{exc.stdout}\n\nstderr:\n{exc.stderr}")
        raise


def prettify_command(args):
    args = [shlex.quote(str(arg)) for arg in args]
    lines = []
    # Place argument names and their values on the same line
    while args:
        arg = args.pop(0)
        if arg.startswith("--") and args and not args[0].startswith("--"):
            next_arg = args.pop(0)
            arg = f"{arg} {next_arg}"
        lines.append(arg)
    return " \\\n  ".join(lines)


if __name__ == "__main__":
    main()
