// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LinkFactory {
  factory Link(head, [Link tail]) {
    return new LinkEntry(head, (tail === null) ? const LinkTail() : tail);
  }

  factory Link.fromList(List list) {
    switch (list.length) {
      case 0:
        return const LinkTail();
      case 1:
        return new Link(list[0]);
      case 2:
        return new Link(list[0], new Link(list[1]));
      case 3:
        return new Link(list[0], new Link(list[1], new Link(list[2])));
    }
    Link link = new Link(list.last());
    for (int i = list.length - 1; i > 0; i--) {
      link = link.prepend(list[i - 1]);
    }
    return link;
  }
}

class AbstractLink<T> implements Link<T> {
  T get head() { throw "bug"; } // TODO(ahe): Work around VM bug.
  T get tail() { throw "bug"; } // TODO(ahe): Work around VM bug.
  abstract List<T> toList(); // TODO(ahe): Work around Frog bug #318.
  abstract bool isEmpty(); // TODO(ahe): Work around Frog bug #318.

  const AbstractLink();

  Link<T> prepend(T element) {
    return new Link<T>(element, this);
  }

  Iterator<T> iterator() => toList().iterator();

  void printOn(StringBuffer buffer, [String separatedBy = '']) {
    if (isEmpty()) return;
    buffer.add(head.toString());
    for (Link link = tail; !link.isEmpty(); link = link.tail) {
      buffer.add(link.head.toString());
      buffer.add(separatedBy);
    }
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.add('[ ');
    printOn(buffer, ', ');
    buffer.add(' ]');
    return buffer.toString();
  }

  Link<T> reverse() {
    Link<T> result = const LinkTail();
    for (Link<T> link = this; !link.isEmpty(); link = link.tail) {
      result = result.prepend(link.head);
    }
    return result;
  }
}

class LinkTail<T> extends AbstractLink<T> implements EmptyLink {
  T get head() => null;
  Link<T> get tail() => null;

  const LinkTail();

  List toList() => const [];

  bool isEmpty() => true;
}

class LinkEntry<T> extends AbstractLink<T> {
  final T head;
  Link<T> realTail;
  Link<T> get tail() => realTail;

  LinkEntry(T this.head, Link<T> this.realTail);

  bool isEmpty() => false;

  List<T> toList() {
    List<T> list = new List<T>();
    for (Link<T> link = this; !link.isEmpty(); link = link.tail) {
      list.addLast(link.head);
    }
    return list;
  }
}

class LinkBuilderImplementation<T> implements LinkBuilder<T> {
  LinkEntry<T> head = null;
  LinkEntry<T> lastLink = null;

  LinkBuilderImplementation();

  Link<T> toLink() {
    if (head === null) return const LinkTail();
    lastLink.realTail = const LinkTail();
    Link<T> link = head;
    lastLink = null;
    head = null;
    return link;
  }

  void addLast(T t) {
    LinkEntry<T> entry = new LinkEntry<T>(t, null);
    if (head === null) {
      head = entry;
    } else {
      lastLink.realTail = entry;
    }
    lastLink = entry;
  }
}