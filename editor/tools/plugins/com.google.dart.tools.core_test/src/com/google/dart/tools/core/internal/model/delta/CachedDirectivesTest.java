/*
 * Copyright (c) 2011, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.tools.core.internal.model.delta;

import junit.framework.TestCase;

import org.eclipse.core.runtime.Assert;

import java.util.HashSet;
import java.util.Set;

public class CachedDirectivesTest extends TestCase {

  public void test_CachedDirectives_CachedDirectives_default() {
    CachedDirectives cd = new CachedDirectives();

    Assert.isNotNull(cd.getImports());
    Assert.isNotNull(cd.getResources());
    Assert.isNotNull(cd.getSources());

    Assert.isTrue(cd.getImports().isEmpty());
    Assert.isTrue(cd.getResources().isEmpty());
    Assert.isTrue(cd.getSources().isEmpty());
  }

  public void test_CachedDirectives_CachedDirectives_non_default() {
    Set<String> imports = set("a");
    Set<String> sources = set("b");
    Set<String> resources = set("c");

    CachedDirectives cd = new CachedDirectives(imports, sources, resources);

    Assert.isTrue(imports.equals(cd.getImports()));
    Assert.isTrue(sources.equals(cd.getSources()));
    Assert.isTrue(resources.equals(cd.getResources()));
  }

  public void test_CachedDirectives_getImports() {
    Set<String> imports = set("1", "2", "3", "4", "4");

    CachedDirectives cd = new CachedDirectives(imports, CachedDirectives.EMPTY_STR_SET,
        CachedDirectives.EMPTY_STR_SET);

    Assert.isTrue(cd.getImports().size() == imports.size());
    Assert.isTrue(cd.getSources().isEmpty());
    Assert.isTrue(cd.getResources().isEmpty());
    Assert.isTrue(imports.equals(cd.getImports()));

    try {
      cd.getImports().add("2");
      fail("UnsupportedOperationException expected but not thrown");
    } catch (UnsupportedOperationException e) {
      // expected
    }
  }

  public void test_CachedDirectives_getResources() {
    Set<String> resources = set("1", "2", "3", "4", "4");

    CachedDirectives cd = new CachedDirectives(CachedDirectives.EMPTY_STR_SET,
        CachedDirectives.EMPTY_STR_SET, resources);

    Assert.isTrue(cd.getImports().isEmpty());
    Assert.isTrue(cd.getSources().isEmpty());
    Assert.isTrue(cd.getResources().size() == resources.size());
    Assert.isTrue(resources.equals(cd.getResources()));

    try {
      cd.getResources().add("2");
      fail("UnsupportedOperationException expected but not thrown");
    } catch (UnsupportedOperationException e) {
      // expected
    }
  }

  public void test_CachedDirectives_getSources() {
    Set<String> sources = set("1", "2", "3", "4", "4");

    CachedDirectives cd = new CachedDirectives(CachedDirectives.EMPTY_STR_SET, sources,
        CachedDirectives.EMPTY_STR_SET);

    Assert.isTrue(cd.getImports().isEmpty());
    Assert.isTrue(cd.getSources().size() == sources.size());
    Assert.isTrue(cd.getResources().isEmpty());
    Assert.isTrue(sources.equals(cd.getSources()));

    try {
      cd.getSources().add("2");
      fail("UnsupportedOperationException expected but not thrown");
    } catch (UnsupportedOperationException e) {
      // expected
    }
  }

  /**
   * Return a modifiable {@link Set} of {@link String}s with the passed input.
   */
  private Set<String> set(String... strings) {
    Set<String> result = new HashSet<String>(strings.length);
    for (String str : strings) {
      result.add(str);
    }
    return result;
  }

}
