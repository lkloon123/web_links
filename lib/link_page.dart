import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:validators/validators.dart';
import 'package:web_links/helper/helper.dart';
import 'package:web_links/model/model.dart';

enum SortDirection {
  asc,
  desc,
}

class LinkPage extends StatefulWidget {
  @override
  _LinkPageState createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newUrlController = TextEditingController();
  List<LinkData> _linkList;
  List<String> _selectedItemId = [];
  bool _isInSelectionState = false;
  SortDirection _currentSortDirection = SortDirection.asc;

  @override
  void initState() {
    super.initState();

    setState(() {
      _linkList = <LinkData>[
        LinkData(url: 'https://www.channelnewsasia.com'),
        LinkData(url: 'https://sg.yahoo.com'),
        LinkData(url: 'https://www.google.com'),
      ];
    });

    //initial loading
    _linkList.forEach((LinkData linkData) {
      Network.loadUrl(linkData.url).then((title) {
        _updateLinkDataTitle(linkData.id, title);
      });
    });
  }

  @override
  void dispose() {
    _newUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (_isInSelectionState) {
          _resetSelectionState();

          return Future.value(false);
        }

        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isInSelectionState
              ? _selectedItemId.length.toString() + ' selected'
              : 'Trial Test'),
          leading: _isInSelectionState
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _resetSelectionState,
                )
              : null,
          actions: _appBarActions(),
        ),
        body: AnimatedList(
          key: _listKey,
          initialItemCount: _linkList.length,
          itemBuilder: (context, index, animation) {
            return _buildItem(_linkList[index], animation);
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _displayAddLinkDialog().then((String newUrl) {
              //when user submit new url
              if (newUrl != null) {
                int newIndex = _linkList.length;
                LinkData newLinkData = LinkData(url: newUrl);

                //insert the newly added url
                setState(() {
                  _linkList = List.from(_linkList)
                    ..insert(newIndex, newLinkData);
                });
                _listKey.currentState.insertItem(newIndex);

                //load the url title
                Network.loadUrl(newUrl).then((title) {
                  _updateLinkDataTitle(newLinkData.id, title);
                });
              }
            });
          },
        ),
      ),
    );
  }

  void _updateLinkDataTitle(String linkDataId, String newTitle) {
    int newLinkDataIndexInState = _linkList.indexWhere(
      (LinkData linkData) => linkData.id == linkDataId,
    );

    setState(() {
      _linkList[newLinkDataIndexInState].title = newTitle;
    });
  }

  List<Widget> _appBarActions() {
    if (_isInSelectionState) {
      return <Widget>[
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _selectedItemId.forEach((String id) {
              LinkData itemToBeRemoved = _linkList.firstWhere(
                (LinkData linkData) => linkData.id == id,
              );
              int indexToBeRemoved = _linkList.indexWhere(
                (LinkData linkData) => linkData.id == id,
              );

              setState(() {
                _linkList = List.from(_linkList)..remove(itemToBeRemoved);
              });
              _listKey.currentState.removeItem(
                indexToBeRemoved,
                (context, animation) => _buildItem(itemToBeRemoved, animation),
              );

              _resetSelectionState();
            });
          },
        ),
      ];
    }

    return <Widget>[
      IconButton(
        icon: Icon(
          _currentSortDirection == SortDirection.asc
              ? FontAwesome5Solid.sort_alpha_down
              : FontAwesome5Solid.sort_alpha_up,
        ),
        onPressed: () {
          if (_currentSortDirection == SortDirection.asc) {
            setState(() {
              _currentSortDirection = SortDirection.desc;
              _linkList = List.from(_linkList)
                ..sort((first, second) => second.url.compareTo(first.url));
            });
          } else {
            setState(() {
              _currentSortDirection = SortDirection.asc;
              _linkList = List.from(_linkList)
                ..sort((first, second) => first.url.compareTo(second.url));
            });
          }
        },
      )
    ];
  }

  void _resetSelectionState() {
    setState(() {
      _selectedItemId = [];
      _isInSelectionState = false;
    });
  }

  Widget _buildItem(LinkData linkData, Animation animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Material(
        color: _selectedItemId.contains(linkData.id)
            ? Colors.grey[400]
            : Colors.white,
        child: ListTile(
          leading: linkData.url != null
              ? Image.network(
                  'https://besticon-demo.herokuapp.com/icon?url=' +
                      linkData.url +
                      '&size=64..64..120',
                )
              : null,
          title: linkData.title != null ? Text(linkData.title) : null,
          subtitle: Text(linkData.url),
          onTap: () {
            setState(() {
              if (_isInSelectionState) {
                if (_selectedItemId.contains(linkData.id)) {
                  _selectedItemId.remove(linkData.id);

                  if (_selectedItemId.isEmpty) {
                    _isInSelectionState = false;
                  }
                } else {
                  _selectedItemId.add(linkData.id);
                }
              }
            });
          },
          onLongPress: () {
            setState(() {
              if (!_isInSelectionState) {
                _isInSelectionState = true;
              }

              _selectedItemId.add(linkData.id);
            });
          },
        ),
      ),
    );
  }

  Future<String> _displayAddLinkDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Website Link'),
          content: Form(
            key: _formKey,
            autovalidate: true,
            child: TextFormField(
              controller: _newUrlController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Link cannot be empty';
                }

                if (!isURL(
                  value,
                  requireProtocol: true,
                  allowUnderscore: true,
                )) {
                  return 'Link must be a valid url';
                }

                return null;
              },
              decoration: InputDecoration(
                hintText: 'e.g. https://2appstudio.com',
              ),
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('ADD'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Navigator.of(context).pop(_newUrlController.text);
                  _newUrlController.clear();
                }
              },
            )
          ],
        );
      },
    );
  }
}
