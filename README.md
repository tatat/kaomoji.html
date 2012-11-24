# kaomoji.html

http://kaomoji.n-at.me/

## API Reference

(API is subject to change without notice)

### Records

#### Resource URL

**GET** *http://kaomoji.n-at.me/kaomoji.json*

#### Paramaters

<table>
  <tbody>
    <tr>
      <th>
        filter<br />
        (optional)
      </th>
      <td>
        Returns results that match a specified value.<br />
        <small>Example Values: ω</small>
      </td>
    </tr>
    <tr>
      <th>
        since<br />
        (optional)
      </th>
      <td>
        Returns results that created since a specified value (unix timestamp).<br />
        <small>Example Values: 1351567940</small>
      </td>
    </tr>
    <tr>
      <th>
        include_created_at<br />
        (optional)
      </th>
      <td>
        Returns results that include created_at. Default to false<br />
        <small>Example Values: true</small>
      </td>
    </tr>
  </tbody>
</table>

#### Example Request

**GET** *http://kaomoji.n-at.me/kaomoji.json?filter=%EF%BC%BE&since=1351567940&include_created_at=true*

    {
      "modified": 1353550341,
      "records": [
        {
          "id": 1763,
          "text": "ふっふっふー（＾Ｏ＾） 私も以前それわかんなくて四苦八苦したのだけれどもねっ！なんと！@を入力してからひとちゃんのhを入力してみましょう！さすれば道は開かれりゅっ！！",
          "created_at": 1351613578
        }
      ]
    }

### Record

#### Resource URL

**GET** *http://kaomoji.n-at.me/:id.json*

#### Paramaters

<table>
  <tbody>
    <tr>
      <th>
        include_created_at<br />
        (optional)
      </th>
      <td>
        Returns results that include created_at. Default to false<br />
        <small>Example Values: true</small>
      </td>
    </tr>
  </tbody>
</table>

#### Example Request

**GET** *http://kaomoji.n-at.me/1763.json*

    {
      "id": 1763,
      "text":"ふっふっふー（＾Ｏ＾） 私も以前それわかんなくて四苦八苦したのだけれどもねっ！なんと！@を入力してからひとちゃんのhを入力してみましょう！さすれば道は開かれりゅっ！！"
    }

### Random

#### Resource URL

**GET** *http://kaomoji.n-at.me/random.json*

#### Paramaters

<table>
  <tbody>
    <tr>
      <th>
        include_created_at<br />
        (optional)
      </th>
      <td>
        Returns results that include created_at. Default to false<br />
        <small>Example Values: true</small>
      </td>
    </tr>
  </tbody>
</table>

#### Example Request

**GET** *http://kaomoji.n-at.me/random.json*

    {
      "id": 1763,
      "text":"ふっふっふー（＾Ｏ＾） 私も以前それわかんなくて四苦八苦したのだけれどもねっ！なんと！@を入力してからひとちゃんのhを入力してみましょう！さすれば道は開かれりゅっ！！"
    }

