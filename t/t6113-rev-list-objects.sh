#!/bin/sh

test_description='git rev-list --objects'

. ./test-lib.sh

test_expect_success setup '
	git init r1 &&

	echo foo >r1/foo &&
	git -C r1 add foo &&
	git -C r1 commit -m foo &&

	echo bar >r1/bar &&
	git -C r1 add bar &&
	git -C r1 commit -m bar &&

	git -C r1 branch -m master alpha
'

test_expect_success 'exclude ^commit and use tree as starting point' '
	git -C r1 rev-list --objects ^HEAD~1 HEAD: >objs &&
	# Should have tree and "bar" file
	test_line_count = 2 objs &&
	grep " bar$" objs &&
	grep " $" objs
'

test_expect_success 'exclude ^commit and use tree+commit as starting points' '
	# Verify that an extra commit starting point does not incorrectly turn
	# off aggressive UNINTERESTING marking.
	#
	# W----X----Y alpha
	#  \
	#   \--Z      beta
	#
	# We will test: git rev-list --objects ^X Y^{tree} Z

	echo baz >r1/baz &&
	git -C r1 add baz &&
	git -C r1 commit -m baz &&
	git -C r1 checkout -b beta alpha~2 &&
	echo other-branch > r1/other-branch &&
	git -C r1 add other-branch &&
	git -C r1 commit -m other-branch &&

	git -C r1 rev-list --objects ^alpha~1 alpha: beta >objs &&

	# Should not have blobs introduced by X or W
	! grep " bar$" objs &&
	! grep " foo$" objs &&

	# Should have blobs introduced by Y and Z
	grep " baz$" objs &&
	grep " other-branch$" objs
'

test_done
