-- set search_path=ct;

create or replace function py_contains(
    txt varchar(64000), patt varchar
    ) returns bool stable as $$
    """ txt ~ patt
    """
    if txt is None:
        return None

    import re
    res = re.search(patt, txt)
    return bool(res)
$$ language plpythonu;

create or replace function py_contains(
    txt varchar(64000), patt varchar, flags varchar(9)
    ) returns bool stable as $$
    """ txt ~ patt with re flags
    """
    if txt is None:
        return None

    import re

    re_patt = r'%s' % patt
    re_flags = 0 #default flags
    for i in flags.upper():
        re_flags |= re.__dict__[i]
    reg = re.compile(re_patt, re_flags)

    res = reg.search(txt)
    return bool(res)
$$ language plpythonu;

CREATE OR REPLACE FUNCTION ct.assert(
    a bool, description VARCHAR
    ) RETURNS BOOLEAN IMMUTABLE AS $$
    assert a, '{description}. see {a}'.format(**locals())
    return True
$$ LANGUAGE plpythonu;
