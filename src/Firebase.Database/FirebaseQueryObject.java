package com.foreign.Firebase.Database;

import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.Query;
import com.google.firebase.database.ValueEventListener;

/**
 * Created by dhvlsimac on 28/03/18.
 */

public class FirebaseQueryObject {

    private String path;
    private Query query;
    private ChildEventListener childEventListener;
    private ValueEventListener valueEventListener;

    FirebaseQueryObject(String path, Query query, ChildEventListener listener) {
        this.path = path;
        this.query = query;
        this.childEventListener = listener;
    }

    FirebaseQueryObject(String path, Query query, ValueEventListener listener) {
        this.path = path;
        this.query = query;
        this.valueEventListener = listener;
    }

    public String getPath() {
        return path;
    }

    public Query getQuery() {
        return query;
    }

    public ChildEventListener getChildEventListener() {
        return childEventListener;
    }

    public ValueEventListener getValueEventListener() {
        return valueEventListener;
    }
}
