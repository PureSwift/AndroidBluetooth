//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift.org project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift.org project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

package org.swift.swiftkit.core.annotations;

import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import static java.lang.annotation.ElementType.*;

/**
 * Value is of an unsigned numeric type.
 * <p>
 * Android-compatible copy of SwiftKitCore's {@code Unsigned} annotation: the
 * upstream source carries {@code jdk.jfr} annotations that are unavailable on
 * Android, so the original is excluded from the source set and replaced by
 * this one.
 */
@Documented
@Target({TYPE_USE, PARAMETER, FIELD, METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface Unsigned {
}
